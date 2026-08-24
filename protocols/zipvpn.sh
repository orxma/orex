#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            ORX TUNNEL MULTI SCRIPT            #
#              ZIVPN AUTO INSTALLER            #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

[[ -f "$CONFIG" ]] && source "$CONFIG"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
WHITE="\e[1;97m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
RESET="\e[0m"

SERVICE="zivpn"

line() {
    printf "${CYAN}%0.s═" {1..55}
    echo -e "${RESET}"
}

title() {
    clear
    line
    echo -e "${WHITE}           🚀 ORX TUNNEL ZIVPN MANAGER${RESET}"
    line
}

ok() {
    echo -e "${GREEN}✔${RESET} $1"
}

error() {
    echo -e "${RED}✘${RESET} $1"
}

info() {
    echo -e "${CYAN}➜${RESET} $1"
}

warn() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

pause() {
    echo
    read -n1 -rsp "Press any key to continue..."
    echo
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#        BUSCAR PUERTO LIBRE AUTOMATIC        #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

find_free_port() {

    local port

    for port in $(shuf -i 20000-29999); do
        if ! ss -lunH | awk '{print $5}' | grep -q ":${port}$"; then
            echo "$port"
            return 0
        fi
    done

    return 1
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#           DETECTAR INTERFAZ DE RED           #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

get_network_interface() {

    local dev

    dev=$(ip route | awk '/default/ {print $5; exit}')

    [[ -z "$dev" ]] && \
    dev=$(ip link show up | awk -F': ' '/state UP/ && $2!="lo"{print $2;exit}')

    echo "$dev"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#         COMPROBAR REQUISITOS DEL VPS         #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

check_system() {

    title

    info "Checking system..."

    [[ $EUID -ne 0 ]] && {
        error "Run the script as root."
        pause
        return 1
    }

    command -v curl >/dev/null || {
        error "curl is not installed."
        pause
        return 1
    }

    command -v openssl >/dev/null || {
        error "openssl is not installed."
        pause
        return 1
    }

    ok "Compatible system."

}

install_zivpn() {

if systemctl is-active --quiet zivpn; then
    warn "ZiVPN ya is installed."
    pause
    return
fi
    title

    check_system || return

    info "Buscando port UDP available..."

    PORT=$(find_free_port)

    [[ -z "$PORT" ]] && {
        error "Not found a port libre entre 20000 y 29999."
        pause
        return
    }

    ok "Port asignado automatically: $PORT"

    echo
    info "Updating repositories..."
    apt-get update -y

    echo
    info "Installing dependencies..."

    apt-get install -y \
        curl \
        wget \
        jq \
        openssl \
        iptables \
        libc6-i386 >/dev/null 2>&1

    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || \
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            BIN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
        ;;
        aarch64|arm64)
            BIN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
        ;;
        *)
            error "Unsupported architecture: $ARCH"
            pause
            return
        ;;
    esac

    mkdir -p /etc/zivpn

    echo
    info "Downloading ZiVPN..."

    curl -L --retry 3 --connect-timeout 10 "$BIN_URL" -o /usr/local/bin/zivpn
if [[ $? -ne 0 ]]; then
    error "Could not download ZiVPN."
    pause
    return
fi
    chmod +x /usr/local/bin/zivpn

    [[ ! -x /usr/local/bin/zivpn ]] && {
        error "Could not download ZiVPN."
        pause
        return
    }

    echo
    info "Generando certificados SSL..."

    openssl req \
        -new \
        -newkey rsa:4096 \
        -nodes \
        -x509 \
        -days 3650 \
        -subj "/C=US/ST=CA/L=LA/O=ZiVPN/CN=zivpn" \
        -keyout /etc/zivpn/zivpn.key \
        -out /etc/zivpn/zivpn.crt

cat >/etc/zivpn/config.json <<EOF
{
    "listen": ":$PORT",
    "cert": "/etc/zivpn/zivpn.crt",
    "key": "/etc/zivpn/zivpn.key",
    "max_conn": 0,
   "auth": {
    "mode": "passwords",
    "config": []
    }
}
EOF

cat >/etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZiVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=2
LimitNOFILE=1048576
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

jq empty /etc/zivpn/config.json || {
    error "Error en config.json"
    pause
    return
}

chmod 600 /etc/zivpn/config.json
chmod 600 /etc/zivpn/zivpn.key
chmod 644 /etc/zivpn/zivpn.crt

    systemctl daemon-reload
    systemctl enable zivpn >/dev/null 2>&1
    systemctl restart zivpn

    configure_zivpn_firewall "$PORT"
if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save >/dev/null 2>&1
elif command -v iptables-save >/dev/null 2>&1; then
    iptables-save >/etc/iptables.rules
fi
    if grep -q "^ZIPVPN=" "$CONFIG"; then
        sed -i 's/^ZIPVPN=.*/ZIPVPN=ON/' "$CONFIG"
    else
        echo "ZIPVPN=ON" >> "$CONFIG"
    fi

    if grep -q "^ZIPVPN_PORT=" "$CONFIG"; then
        sed -i "s/^ZIPVPN_PORT=.*/ZIPVPN_PORT=\"$PORT\"/" "$CONFIG"
    else
        echo "ZIPVPN_PORT=\"$PORT\"" >> "$CONFIG"
    fi

    source "$CONFIG"

    sleep 2

    if systemctl is-active --quiet zivpn; then

        title

        ok "ZiVPN installed successfully."

        echo
        echo " Service : zivpn"
        echo " Status   : Active"
        echo " Port   : $PORT"
        echo " Rango    : 20000-29999"
        echo " Config   : /etc/zivpn/config.json"
        echo " SSL      : Habilitado"

    else

        error "The service could not start."

        journalctl -u zivpn --no-pager -n 20

    fi

    pause
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#           CONFIGURAR IPTABLES                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

configure_zivpn_firewall() {

    local PORT="$1"

    info "Configuring firewall..."

    DEV=$(get_network_interface)

    [[ -z "$DEV" ]] && {
        error "Could not detect the network interface."
        return 1
    }

    ok "Interface detectada: $DEV"

    # Delete previous rules
    while iptables -t nat -C PREROUTING -i "$DEV" -p udp --dport 20000:29999 -j REDIRECT --to-port "$PORT" &>/dev/null; do
        iptables -t nat -D PREROUTING -i "$DEV" -p udp --dport 20000:29999 -j REDIRECT --to-port "$PORT"
    done

    while iptables -C INPUT -p udp --dport 20000:29999 -j ACCEPT &>/dev/null; do
        iptables -D INPUT -p udp --dport 20000:29999 -j ACCEPT
    done

    while iptables -C INPUT -p udp --dport "$PORT" -j ACCEPT &>/dev/null; do
        iptables -D INPUT -p udp --dport "$PORT" -j ACCEPT
    done

    iptables -t nat -D POSTROUTING -o "$DEV" -j MASQUERADE 2>/dev/null

    # Add reglas
    iptables -t nat -A PREROUTING \
        -i "$DEV" \
        -p udp \
        --dport 20000:29999 \
        -j REDIRECT \
        --to-port "$PORT"

    iptables -A INPUT \
        -p udp \
        --dport "$PORT" \
        -j ACCEPT

    iptables -A INPUT \
        -p udp \
        --dport 20000:29999 \
        -j ACCEPT

    iptables -t nat -A POSTROUTING \
        -o "$DEV" \
        -j MASQUERADE

    ok "Firewall configured successfully."

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            REINICIAR SERVICE                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

restart_zivpn() {

    title

    info "Restarting ZiVPN..."

    systemctl restart zivpn

    sleep 2

    if systemctl is-active --quiet zivpn; then
        ok "Service restarted successfully."
    else
        error "Could not restart ZiVPN."
    fi

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#               SERVICE STATUS            #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

status_zivpn() {

    title

    if systemctl is-active --quiet zivpn; then
        STATUS="${GREEN}🟢 ACTIVE${RESET}"
    else
        STATUS="${RED}🔴 STOPPED${RESET}"
    fi

    PORT="-"

    [[ -f /etc/zivpn/config.json ]] && \
    PORT=$(jq -r '.listen' /etc/zivpn/config.json | tr -d ':')

    echo
    echo -e " Status     : $STATUS"
    echo -e " Service   : zivpn"
    echo -e " Port UDP : $PORT"
    echo -e " Rango UDP  : 20000-29999"
    echo

    line

    systemctl --no-pager --full status zivpn

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             DESINSTALL ZIVPN                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

remove_zivpn() {

    title

    warn "will be completely removed ZiVPN."

    echo

    read -rp "Continue? [y/N]: " R

    [[ ! "$R" =~ ^[Ss]$ ]] && return

    PORT=$(jq -r '.listen' /etc/zivpn/config.json 2>/dev/null | tr -d ':')

    DEV=$(get_network_interface)

    systemctl stop zivpn 2>/dev/null
    systemctl disable zivpn 2>/dev/null

    rm -f /etc/systemd/system/zivpn.service
    rm -rf /etc/zivpn
    rm -f /usr/local/bin/zivpn

    if [[ -n "$DEV" ]]; then

        iptables -t nat -D PREROUTING \
            -i "$DEV" \
            -p udp \
            --dport 20000:29999 \
            -j REDIRECT \
            --to-port "$PORT" 2>/dev/null

        iptables -D INPUT \
            -p udp \
            --dport "$PORT" \
            -j ACCEPT 2>/dev/null

        iptables -D INPUT \
            -p udp \
            --dport 20000:29999 \
            -j ACCEPT 2>/dev/null

        iptables -t nat -D POSTROUTING \
            -o "$DEV" \
            -j MASQUERADE 2>/dev/null

    fi

    systemctl daemon-reload
    systemctl reset-failed

    if grep -q "^ZIPVPN=" "$CONFIG"; then
        sed -i 's/^ZIPVPN=.*/ZIPVPN=OFF/' "$CONFIG"
    else
        echo "ZIPVPN=OFF" >> "$CONFIG"
    fi

    sed -i '/^ZIPVPN_PORT=/d' "$CONFIG"

    source "$CONFIG"

    echo

    ok "ZiVPN was deleted successfully."

    pause

}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#       SINCRONIZAR CUENTA SSH CON ZIVPN       #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

sync_zivpn_password() {

    local USER="$1"
    local PASS="$2"

    [[ -z "$USER" || -z "$PASS" ]] && return 1

    [[ ! -f /etc/zivpn/config.json ]] && return 1

    # If it already exists, do not duplicate it
    if jq -e --arg pass "$PASS" \
        '.auth.config[] | select(. == $pass)' \
        /etc/zivpn/config.json >/dev/null 2>&1; then
        return 0
    fi

    local TMP
    TMP=$(mktemp)

    if jq --arg pass "$PASS" \
        '.auth.config += [$pass]' \
        /etc/zivpn/config.json > "$TMP"; then

        mv "$TMP" /etc/zivpn/config.json
        chmod 600 /etc/zivpn/config.json

        systemctl restart zivpn >/dev/null 2>&1

        return 0
    fi

    rm -f "$TMP"
    return 1
}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            ADD PASSWORD                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

add_zivpn_password() {

    title

    [[ ! -f /etc/zivpn/config.json ]] && {
        error "ZiVPN is not installed."
        pause
        return
    }

    read -rp "Enter the new password: " PASS

    [[ -z "$PASS" ]] && {
        error "The password cannot be empty."
        pause
        return
    }

    if jq -e --arg pass "$PASS" '.auth.config[] | select(.==$pass)' \
        /etc/zivpn/config.json >/dev/null; then

        error "The password already exists."
        pause
        return

    fi

    TMP=$(mktemp)

    jq --arg pass "$PASS" \
        '.auth.config += [$pass]' \
        /etc/zivpn/config.json > "$TMP"

    mv "$TMP" /etc/zivpn/config.json

    systemctl restart zivpn

    ok "Password added successfully."

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            DELETE PASSWORD               #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

remove_zivpn_password() {

    title

    [[ ! -f /etc/zivpn/config.json ]] && {
        error "ZiVPN is not installed."
        pause
        return
    }

    mapfile -t PASSLIST < <(
        jq -r '.auth.config[]' /etc/zivpn/config.json
    )

    [[ ${#PASSLIST[@]} -eq 0 ]] && {
        error "No passwords are registered."
        pause
        return
    }

    echo

    for ((i=0;i<${#PASSLIST[@]};i++)); do
        printf " [%02d] %s\n" "$((i+1))" "${PASSLIST[$i]}"
    done

    echo

    read -rp "Select a password: " OP

    [[ ! "$OP" =~ ^[0-9]+$ ]] && {
        error "Option invalid."
        pause
        return
    }

    INDEX=$((OP-1))

    [[ $INDEX -lt 0 || $INDEX -ge ${#PASSLIST[@]} ]] && {
        error "Option invalid."
        pause
        return
    }

    PASS="${PASSLIST[$INDEX]}"

    TMP=$(mktemp)

    jq --arg pass "$PASS" \
        '.auth.config |= map(select(. != $pass))' \
        /etc/zivpn/config.json > "$TMP"

    mv "$TMP" /etc/zivpn/config.json

    systemctl restart zivpn

    ok "Password deleted successfully."

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             LISTR PASSWORDS               #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

list_zivpn_passwords() {

    title

    [[ ! -f /etc/zivpn/config.json ]] && {
        error "ZiVPN is not installed."
        pause
        return
    }

    echo

    TOTAL=$(jq '.auth.config | length' /etc/zivpn/config.json)

    echo " Total of passwords : $TOTAL"

    line

    jq -r '.auth.config[]' /etc/zivpn/config.json | nl -w2 -s". "

    line

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#               VER LOGS ZIVPN                 #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

view_zivpn_logs() {

    title

    info "Latest 50 logs of the service"

    line

    journalctl -u zivpn --no-pager -n 50

    line

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             DIAGNOSTICS ZIVPN                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

check_zivpn() {

    title

    [[ -x /usr/local/bin/zivpn ]] \
        && ok "Binario ZiVPN" \
        || error "Binario ZiVPN"

    [[ -f /etc/zivpn/config.json ]] \
        && ok "File config.json" \
        || error "File config.json"

    [[ -f /etc/zivpn/zivpn.crt ]] \
        && ok "Certificado SSL" \
        || error "Certificado SSL"

    [[ -f /etc/zivpn/zivpn.key ]] \
        && ok "Llave private" \
        || error "Llave private"

    if systemctl is-active --quiet zivpn; then
        ok "Service running"
    else
        error "Service stopped"
    fi

    PORT="-"

    [[ -f /etc/zivpn/config.json ]] && \
    PORT=$(jq -r '.listen' /etc/zivpn/config.json | tr -d ':')

    echo
    line
    echo "Port UDP : $PORT"
    echo "Proceso"
    line

    ss -lunp | grep "$PORT"

    line

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          SERVER INFORMATION            #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

system_info() {

    title

    HOST=$(hostname)

    IP=$(curl -4 -s ipv4.icanhazip.com 2>/dev/null)

    OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

    KERNEL=$(uname -r)

    UPTIME=$(uptime -p)

    RAM=$(free -h | awk '/Mem:/ {print $3" / "$2}')

    DISK=$(df -h / | awk 'NR==2 {print $3" / "$2" ("$5")"}')

    CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')

    CORES=$(nproc)

    echo
    echo " Hostname : $HOST"
    echo " System  : $OS"
    echo " Kernel   : $KERNEL"
    echo " CPU      : $CPU"
    echo " Cores  : $CORES"
    echo " Memoria  : $RAM"
    echo " Disco    : $DISK"
    echo " Uptime   : $UPTIME"
    echo " IPv4     : ${IP:-No available}"

    line

    echo "Load dthe system"

    uptime

    line

    pause

}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#               AUTOMATIC MODE                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

if [[ "$1" == "--auto" ]]; then
    echo "🚀 Installing ZiVPN automatically..."

    install_zivpn

    if systemctl is-active --quiet zivpn; then
        echo "✅ ZiVPN installed successfully."
        exit 0
    else
        echo "❌ Error installing ZiVPN."
        exit 1
    fi
fi
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#                 MAIN MENU               #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

while true; do

    title

    if systemctl is-active --quiet zivpn; then
        STATUS="${GREEN}🟢 ACTIVE${RESET}"
    else
        STATUS="${RED}🔴 STOPPED${RESET}"
    fi

    if [[ -f /etc/zivpn/config.json ]]; then
        PORT=$(jq -r '.listen' /etc/zivpn/config.json | tr -d ':')
    else
        PORT="Not installed"
    fi

    VERSION="-"

    if [[ -x /usr/local/bin/zivpn ]]; then
        VERSION=$(/usr/local/bin/zivpn version 2>/dev/null | head -n1)
        [[ -z "$VERSION" ]] && VERSION="1.4.9"
    fi

    ARCH=$(uname -m)
printf "${CYAN}║${RESET} Status       : %-29b ${CYAN}║${RESET}\n" "$STATUS"
printf "${CYAN}║${RESET} Service     : %-29s ${CYAN}║${RESET}\n" "zivpn"
printf "${CYAN}║${RESET} Port UDP   : %-29s ${CYAN}║${RESET}\n" "$PORT"
printf "${CYAN}║${RESET} Rango UDP    : %-29s ${CYAN}║${RESET}\n" "20000-29999"
printf "${CYAN}║${RESET} Arquitectura : %-29s ${CYAN}║${RESET}\n" "$ARCH"
printf "${CYAN}║${RESET} Version      : %-29s ${CYAN}║${RESET}\n" "$VERSION"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"

    echo

    if [[ "$ZIPVPN" == "ON" ]]; then

cat <<EOF
 [1] Reinstall ZiVPN
 [2] Restart Service
 [3] Status of the Service
 [4] Add Password
 [5] Delete Password
 [6] Listr Passwords
 [7] View Logs
 [8] Diagnostics
 [9] Information of the Server
 [10] Uninstall ZiVPN
 [0] Return
EOF

    else

cat <<EOF
 [1] Install ZiVPN
 [0] Return
EOF

    fi

    line

    read -rp "Select an option: " OP

    case "$OP" in

        1)
            install_zivpn
        ;;

        2)
            restart_zivpn
        ;;

        3)
            status_zivpn
        ;;

        4)
            add_zivpn_password
        ;;

        5)
            remove_zivpn_password
        ;;

        6)
            list_zivpn_passwords
        ;;

        7)
            view_zivpn_logs
        ;;

        8)
            check_zivpn
        ;;

        9)
            system_info
        ;;

        10)
            remove_zivpn
        ;;

        0)
            exec bash "$BASE/protocols/menu.sh"
        ;;

        *)
            error "Option invalid."
            sleep 2
        ;;

    esac

done
