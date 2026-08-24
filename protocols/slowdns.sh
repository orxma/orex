#!/bin/bash

#==================================================
# ORX Tunnel Multi Script Premium
# SlowDNS + DNSDist Manager
# Compatible:
# • HTTP Injector
# • HTTP Custom
# • UDP Custom
# • TLS Tunnel
#==================================================

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

[[ -f "$CONFIG" ]] || {
    echo "❌ Does not exist $CONFIG"
    exit 1
}

source "$CONFIG"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
WHITE="\e[1;97m"
RESET="\e[0m"

SERVICE="slowdns"
DNSDIST="dnsdist"

DIR="/etc/slowdns"

BIN="/usr/bin/slowdns-server"

PUBKEY="$DIR/server.pub"
PRIVKEY="$DIR/server.key"

DOMAIN_FILE="$DIR/domain.conf"

DNS_PORT="53"
SLOWDNS_PORT="5300"

STATUS=""
#==================================================
# Install dependencies
#==================================================

install_dependencies(){

    echo "📦 Installing dependencies..."

    apt update -y

    apt install -y \
        curl \
        wget \
        dnsdist \
        iptables \
        dnsutils \
        ca-certificates

    mkdir -p "$DIR"

}

#==================================================
# Download SlowDNS Server
#==================================================

install_slowdns_binary(){

    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            BIN_NAME="dnstt-server-linux-amd64"
        ;;
        aarch64|arm64)
            BIN_NAME="dnstt-server-linux-arm64"
        ;;
        i386|i686)
            BIN_NAME="dnstt-server-linux-386"
        ;;
        *)
            echo "❌ Unsupported architecture: $ARCH"
            return 1
        ;;
    esac

    MIRRORS=(
        "https://dnstt.network/$BIN_NAME"
        "https://github.com/bugfloyd/dnstt-deploy/raw/main/bin/$BIN_NAME"
        "https://raw.githubusercontent.com/Dan3651/scripts/main/slowdns-server"
    )

    echo ""
    echo "⬇️ Downloading SlowDNS Server..."

    if [[ -x "$BIN" ]]; then
        echo "✅ SlowDNS Server already exists."
        return 0
    fi

    rm -f "$BIN"

    SUCCESS=0

    for URL in "${MIRRORS[@]}"
    do
        echo "🌐 Probando: $URL"

        if curl -L -k -s -f "$URL" -o "$BIN"; then

            chmod +x "$BIN"

            if "$BIN" -h >/dev/null 2>&1; then
                SUCCESS=1
                break
            fi
        fi

        rm -f "$BIN"

    done

    if [[ $SUCCESS -eq 0 ]]; then
        echo "❌ Could not download SlowDNS Server."
        return 1
    fi

    echo "✅ SlowDNS Server installed."

}

#==================================================
# Generar keys
#==================================================

generate_keys(){

    echo "🔑 Generando keys..."

    if [[ ! -f "$PUBKEY" || ! -f "$PRIVKEY" ]]; then

        "$BIN" \
            -gen-key \
            -privkey-file "$PRIVKEY" \
            -pubkey-file "$PUBKEY"

    fi

}
#==================================================
# Configurar DNSDist
#==================================================

configure_dnsdist(){

    echo "⚙️ Configurando DNSDist..."

    DOMAIN=$(cat "$DOMAIN_FILE")

    mkdir -p /etc/dnsdist

    cat > /etc/dnsdist/dnsdist.conf <<EOF
-- ORX Tunnel Multi Script Premium

setLocal("0.0.0.0:5380")
addLocal("[::]:5380")

addACL("0.0.0.0/0")
addACL("::/0")

newServer({
    address="127.0.0.1:5300",
    name="slowdns",
    pool="slowdns"
})

addAction(
    RegexRule("$(echo "$DOMAIN" | sed 's/\./\\\\./g')"),
    PoolAction("slowdns")
)
EOF

if ! dnsdist --check-config >/dev/null 2>&1; then
    echo "❌ Error en dnsdist.conf"
    dnsdist --check-config
    return 1
fi
    systemctl daemon-reload

    systemctl enable dnsdist >/dev/null 2>&1

}
#==================================================
# Crear service SlowDNS
#==================================================

create_slowdns_service(){

    DOMAIN=$(cat "$DOMAIN_FILE")

    cat > /etc/systemd/system/slowdns.service <<EOF
[Unit]
Description=ORX Tunnel SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DIR
ExecStart=$BIN -udp :5300 -privkey-file $PRIVKEY $DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable slowdns

}

#==================================================
# Abrir port DNS
#==================================================

open_dns_port(){

    echo "🛡 Configurando reglas DNS..."

    # Limpiar reglas antiguas IPv4
    while iptables -t nat -C PREROUTING \
        -p udp --dport 53 \
        -m u32 --u32 "0>>22&0x3C@12=0x00010000" \
        -j REDIRECT --to-ports 5380 2>/dev/null
    do
        iptables -t nat -D PREROUTING \
            -p udp --dport 53 \
            -m u32 --u32 "0>>22&0x3C@12=0x00010000" \
            -j REDIRECT --to-ports 5380
    done

    # Limpiar reglas antiguas IPv6
    while ip6tables -t nat -C PREROUTING \
        -p udp --dport 53 \
        -j REDIRECT --to-ports 5380 2>/dev/null
    do
        ip6tables -t nat -D PREROUTING \
            -p udp --dport 53 \
            -j REDIRECT --to-ports 5380
    done

    # Add regla IPv4 (igual que el Go)
    iptables -t nat -I PREROUTING 1 \
        -p udp \
        --dport 53 \
        -m u32 \
        --u32 "0>>22&0x3C@12=0x00010000" \
        -j REDIRECT \
        --to-ports 5380

    # Add regla IPv6
    ip6tables -t nat -I PREROUTING 1 \
        -p udp \
        --dport 53 \
        -j REDIRECT \
        --to-ports 5380

    echo "✅ Reglas DNS aplicadas."

}
#==================================================
# Install SlowDNS
#==================================================

install_slowdns(){

    clear

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}        🚀 INSTALL SLOWDNS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    read -rp "🌐 Domain NS (Ej: ns.midomain.com): " DOMAIN

    [[ -z "$DOMAIN" ]] && {
        echo "❌ Domain invalid."
        sleep 2
        return
    }

    install_dependencies || return

    install_slowdns_binary || return

    mkdir -p "$DIR"

    echo "$DOMAIN" > "$DOMAIN_FILE"

    generate_keys || return

    configure_dnsdist
systemctl restart dnsdist

sleep 1
    create_slowdns_service

    open_dns_port

    echo ""
    echo "🔄 Starting services..."

    systemctl daemon-reload

systemctl enable dnsdist >/dev/null 2>&1
systemctl enable slowdns >/dev/null 2>&1

# Restart dnsdist first
systemctl restart dnsdist

sleep 2

# Verificar que dnsdist is now active
if ! systemctl is-active --quiet dnsdist; then
    echo "❌ dnsdist could not start."
    journalctl -u dnsdist -n 20 --no-pager
    return 1
fi

# Iniciar SlowDNS
systemctl restart slowdns

sleep 2

# Verificar SlowDNS
if ! systemctl is-active --quiet slowdns; then
    echo "❌ SlowDNS could not start."
    journalctl -u slowdns -n 20 --no-pager
    return 1
fi

    sleep 3

    if systemctl is-active --quiet dnsdist && \
       systemctl is-active --quiet slowdns
    then

        sed -i '/^SLOWDNS=/d' "$CONFIG"
        echo "SLOWDNS=ON" >> "$CONFIG"

        source "$CONFIG"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "      ✅ SLOWDNS INSTALLED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 Domain : $(cat "$DOMAIN_FILE")"
        echo ""
        echo "🔑 Public Key:"
        cat "$PUBKEY"
        echo ""
        echo "🌍 DNS : 53"
        echo "🐌 DNSTT : 5300"
        echo ""

    else

        echo ""
        echo "❌ Error iniciando SlowDNS"
        echo ""

        systemctl status slowdns --no-pager
        echo ""
        systemctl status dnsdist --no-pager

    fi

    sleep 4

}
#==================================================
# Delete SlowDNS
#==================================================

remove_slowdns(){

    clear

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}        🗑 DELETE SLOWDNS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    read -rp "Delete SlowDNS? (s/n): " R

    [[ ! "$R" =~ ^[Ss]$ ]] && return

    systemctl stop slowdns 2>/dev/null
    systemctl stop dnsdist 2>/dev/null

    systemctl disable slowdns 2>/dev/null
    systemctl disable dnsdist 2>/dev/null

    rm -f /etc/systemd/system/slowdns.service
    rm -f /etc/dnsdist/dnsdist.conf

    rm -rf "$DIR"

    rm -f "$BIN"

    systemctl daemon-reload

    iptables -t nat -D PREROUTING \
    -p udp \
    --dport 53 \
    -m u32 \
    --u32 "0>>22&0x3C@12=0x00010000" \
    -j REDIRECT \
    --to-ports 5380 2>/dev/null

ip6tables -t nat -D PREROUTING \
    -p udp \
    --dport 53 \
    -j REDIRECT \
    --to-ports 5380 2>/dev/null

    sed -i '/^SLOWDNS=/d' "$CONFIG"
    echo "SLOWDNS=OFF" >> "$CONFIG"

    source "$CONFIG"

    echo ""
    echo "✅ SlowDNS deleted."

    sleep 3

}

#==================================================
# Restart services
#==================================================

restart_slowdns(){

    clear

    echo "🔄 Restarting services..."

    systemctl restart dnsdist
    systemctl restart slowdns

    sleep 2

    if systemctl is-active --quiet dnsdist && \
       systemctl is-active --quiet slowdns
    then
        echo ""
        echo "✅ Services actives."
    else
        echo ""
        echo "❌ Restart failed."
    fi

    sleep 3

}

#==================================================
# Status
#==================================================

status_slowdns(){

    clear

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}         📊 STATUS SLOWDNS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo ""
    systemctl status slowdns --no-pager

    echo ""
    systemctl status dnsdist --no-pager

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "Ports abiertos:"
    ss -ulnp | grep -E "53|5300" || true

    echo ""
    echo "Domain:"
    [[ -f "$DOMAIN_FILE" ]] && cat "$DOMAIN_FILE"

    echo ""
    echo "Public Key:"
    [[ -f "$PUBKEY" ]] && cat "$PUBKEY"

    echo ""
    read -n1 -r -p "Press any key..."

}

#==================================================
# Show Public Key
#==================================================

show_key(){

    clear

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}          🔑 PUBLIC KEY${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    if [[ -f "$PUBKEY" ]]; then
        cat "$PUBKEY"
    else
        echo "❌ Does not exist la Public Key."
    fi

    echo ""
    read -n1 -r -p "Press any key..."

}
#==================================================
# AUTOMATIC MODE
#==================================================

if [[ "$1" == "--auto" ]]; then
    install_slowdns
    exit 0
fi
#==================================================
# Menu Principal
#==================================================

while true
do

    clear

    source "$CONFIG"

    if systemctl is-active --quiet slowdns; then
        STATUS="${GREEN}🟢 ACTIVE${RESET}"
    else
        STATUS="${RED}🔴 STOPPED${RESET}"
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}           🐌 SLOWDNS MANAGER${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo -e " Status      : $STATUS"
    echo -e " Port DNS  : 53"
    echo -e " DNSTT       : 5300"

    if [[ -f "$DOMAIN_FILE" ]]; then
        echo -e " Domain NS  : ${YELLOW}$(cat "$DOMAIN_FILE")${RESET}"
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [[ "$SLOWDNS" == "ON" ]]; then

cat <<EOF

 [1] ➮ Uninstall SlowDNS
 [2] ➮ Restart Services
 [3] ➮ View Status
 [4] ➮ View Public Key

 [0] ➮ Return

EOF

    else

cat <<EOF

 [1] ➮ Install SlowDNS

 [0] ➮ Return

EOF

    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    read -rp " ► Option: " OP

    case "$OP" in

        1)

            if [[ "$SLOWDNS" == "ON" ]]; then
                remove_slowdns
            else
                install_slowdns
            fi

        ;;

        2)

            [[ "$SLOWDNS" == "ON" ]] && restart_slowdns

        ;;

        3)

            [[ "$SLOWDNS" == "ON" ]] && status_slowdns

        ;;

        4)

            [[ "$SLOWDNS" == "ON" ]] && show_key

        ;;

        0)

            exec bash "$BASE/protocols/menu.sh"

        ;;

        *)

            echo ""
            echo "❌ Option invalid."
            sleep 2

        ;;

    esac

done
