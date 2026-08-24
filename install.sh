#!/bin/bash

#=========================================================
#        ORX TUNNEL INSTALLER
#        PREMIUM COLOR EDITION
#=========================================================

set -o pipefail

#=========================================================
# COLORES
#=========================================================

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

BLACK="\e[1;30m"
RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

# Colores 256
PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
VIOLET="\e[38;5;177m"
SKY="\e[38;5;117m"
LIME="\e[38;5;154m"
GOLD="\e[38;5;220m"
ORANGE="\e[38;5;214m"
AQUA="\e[38;5;159m"

#=========================================================
# VARIABLES
#=========================================================

BASE="/etc/orx-tunnel"
TMP="/tmp/orx-tunnel_install"

BASE_URL="https://sc.orx.ma"
MANIFEST_URL="${BASE_URL}/manifest.txt"

#=========================================================
# CONFIGURATION
#=========================================================

INSTALL_PROTOCOLS="ON"

SERVER_DOMAIN=""
SERVER_IP=""
DOMAIN_IP=""
DOMAIN_IP_MATCH="NO"
DNS_PROVIDER="Unknown"

SSL_TUNNEL="OFF"
PROXY_STATUS="OFF"

CLIENT_IP=""
OS_NAME=""
HOSTNAME_VALUE=""
DATE_NOW=""

#=========================================================
# FUNCIONES VISUALES
#=========================================================

clear_screen() {
    clear 2>/dev/null || true
}

linea() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

linea_color() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titulo() {

    clear_screen

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${PINK}${BOLD}                    ORX TUNNEL${RESET}                    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} ${PURPLE}                    INSTALLER v2.0.0${RESET}                ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${SKY}                 🚀  S E R V E R   E D I T I O N  🚀${RESET}"
    echo

}

seccion() {

    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD} $1${RESET}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

}

ok() {
    echo -e " ${GREEN}✔${RESET} ${WHITE}$1${RESET}"
}

info() {
    echo -e " ${CYAN}◆${RESET} ${WHITE}$1${RESET}"
}

warn() {
    echo -e " ${YELLOW}⚠${RESET} ${WHITE}$1${RESET}"
}

fail() {
    echo -e " ${RED}✖${RESET} ${WHITE}$1${RESET}"
}

loading() {

    local TEXT="$1"

    echo -ne " ${CYAN}${TEXT}${RESET} "

    for i in 1 2 3; do
        echo -ne "${PURPLE}●${RESET}"
        sleep 0.18
    done

    echo

}

barra() {

    local TEXT="$1"
    local WIDTH=35

    echo -ne " ${SKY}${TEXT}${RESET} ["

    for ((i=0; i<WIDTH; i++)); do
        echo -ne "${CYAN}█${RESET}"
        sleep 0.015
    done

    echo "] ${GREEN}100%${RESET}"

}

error_exit() {

    echo
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}❌ INSTALLATION DETENIDA${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e " ${RED}✖${RESET} ${WHITE}$1${RESET}"
    echo
    exit 1

}

pausa() {
    sleep "${1:-1}"
}

#=========================================================
# ROOT
#=========================================================

if [[ "$EUID" -ne 0 ]]; then

    echo
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}🔒 PERMISOS ROOT NECESARIOS${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${YELLOW}Run:${RESET}"
    echo
    echo -e "${CYAN}sudo -i${RESET}"
    echo
    exit 1

fi

#=========================================================
# UBUNTU CHECK
#=========================================================

if [[ ! -f /etc/os-release ]]; then
    error_exit "Could not detect the operating system."
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
    error_exit "This installer is only compatible with Ubuntu."
fi

#=========================================================
# CABECERA
#=========================================================

titulo

echo -e "${GREEN}             ● COMPATIBLE SYSTEM DETECTED ●${RESET}"
echo
echo -e "${WHITE}System : ${SKY}${PRETTY_NAME}${RESET}"
echo -e "${WHITE}User : ${GOLD}root${RESET}"
echo
linea_color

#=========================================================
# PASO 0
# DEPENDENCIAS
#=========================================================

seccion "📦 STEP 0  •  PREPARING SYSTEM"

echo -e "${GRAY}Initializing required components...${RESET}"
echo

loading "Updating repositories"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y >/dev/null 2>&1 || \
    error_exit "Could not update the repositories."

ok "Repositories updated."

loading "Installing dependencies"

apt-get install -y \
    curl \
    wget \
    git \
    jq \
    ca-certificates \
    dnsutils \
    sudo \
    openssl \
    >/dev/null 2>&1 || \
    error_exit "Could not install the dependencies."

update-ca-certificates >/dev/null 2>&1 || true

ok "Dependencias installeds."
echo

#=========================================================
# STEP 2
# SYSTEM
#=========================================================

seccion "⚙️ STEP 2  •  PREPARING SERVER"

echo -e "${GRAY}Configuring main VPS components.${RESET}"
echo

loading "Updating packages"

apt-get update -y >/dev/null 2>&1 || \
    error_exit "Error updating repositories."

loading "Installing components"

apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    tar \
    sudo \
    nano \
    cron \
    net-tools \
    dnsutils \
    lsof \
    screen \
    jq \
    bc \
    socat \
    openssl \
    ca-certificates \
    openssh-server \
    ufw \
    fail2ban \
    >/dev/null 2>&1 || \
    error_exit "Could not install all packages."

ok "Components installed."

#=========================================================
# OPENSSH
#=========================================================

echo
info "Configuring OpenSSH..."

systemctl enable ssh >/dev/null 2>&1 || true

systemctl restart ssh >/dev/null 2>&1 || \
    error_exit "Could not start OpenSSH."

ok "OpenSSH active."

#=========================================================
# FIREWALL
#=========================================================

echo
info "Configuring firewall..."

ufw --force reset >/dev/null 2>&1 || true

ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw allow 22/tcp >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1

ufw --force enable >/dev/null 2>&1 || true

ok "Firewall configured."

#=========================================================
# SSH HARDENING
#=========================================================

echo
info "Applying SSH security..."

SSHD_CFG="/etc/ssh/sshd_config"

if [[ -f "$SSHD_CFG" ]]; then

    cp "$SSHD_CFG" "${SSHD_CFG}.orx-tunnel.backup"

    sed -i \
        -e '/^[[:space:]]*#\?[[:space:]]*PermitRootLogin[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*MaxAuthTries[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveInterval[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveCountMax[[:space:]]/d' \
        "$SSHD_CFG"

    cat >> "$SSHD_CFG" <<'EOF'

#=========================================================
# ORX Tunnel SSH configuration
#=========================================================

PermitRootLogin prohibit-password
PasswordAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

EOF

fi

if sshd -t >/dev/null 2>&1; then

    systemctl restart ssh

    ok "Configuration SSH valid."

else

    fail "Error in SSH configuration."

    if [[ -f "${SSHD_CFG}.orx-tunnel.backup" ]]; then

        cp \
            "${SSHD_CFG}.orx-tunnel.backup" \
            "$SSHD_CFG"

        systemctl restart ssh

        ok "Previous configuration restored."

    fi

fi

#=========================================================
# FAIL2BAN
#=========================================================

echo
info "Configuring Fail2Ban..."

mkdir -p /etc/fail2ban

cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
backend = systemd
EOF

systemctl enable fail2ban >/dev/null 2>&1 || true
systemctl restart fail2ban >/dev/null 2>&1 || true

ok "Fail2Ban configured."

#=========================================================
# STEP 3
# DOMAIN
#=========================================================

seccion "🌐 STEP 3  •  DOMAIN CONFIGURATION"

read -r -p "$(echo -e "${CYAN}🌐 Domain of the VPS:${RESET} ")" SERVER_DOMAIN

SERVER_DOMAIN="$(
    printf '%s' "$SERVER_DOMAIN" |
    tr -d '[:space:]'
)"

SERVER_IP="$(
    curl \
        --silent \
        --show-error \
        --connect-timeout 5 \
        --max-time 10 \
        -4 \
        https://api.ipify.org \
        2>/dev/null
)"

if [[ -z "$SERVER_IP" ]]; then
    SERVER_IP="Unknown"
fi

DOMAIN_IP_MATCH="NO"
DNS_PROVIDER="Unknown"

if [[ -n "$SERVER_DOMAIN" ]]; then

    echo
    loading "Checking DNS"

    DOMAIN_IP="$(
        dig +short A "$SERVER_DOMAIN" |
        grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' |
        head -n1
    )"

    if [[ -n "$DOMAIN_IP" &&
          "$DOMAIN_IP" == "$SERVER_IP" ]]; then

        DOMAIN_IP_MATCH="YES"

        ok "The domain points successfully to the VPS."

    else

        warn "The domain does not point to this VPS yet."

        if [[ -n "$DOMAIN_IP" ]]; then

            echo -e " ${GRAY}IP found:${RESET} ${YELLOW}$DOMAIN_IP${RESET}"
            echo -e " ${GRAY}IP of the VPS:   ${RESET} ${CYAN}$SERVER_IP${RESET}"

        fi

    fi

    NS="$(
        dig +short NS "$SERVER_DOMAIN" |
        tr '\n' ' '
    )"

    if echo "$NS" | grep -qi "cloudflare"; then
        DNS_PROVIDER="Cloudflare"

    elif echo "$NS" | grep -Eqi "awsdns|route53"; then
        DNS_PROVIDER="AWS Route 53"

    elif echo "$NS" | grep -Eqi "googledomains|google"; then
        DNS_PROVIDER="Google Cloud DNS"

    elif echo "$NS" | grep -qi "azure"; then
        DNS_PROVIDER="Azure DNS"

    elif echo "$NS" | grep -qi "namecheap"; then
        DNS_PROVIDER="Namecheap"

    elif echo "$NS" | grep -qi "godaddy"; then
        DNS_PROVIDER="GoDaddy"

    elif echo "$NS" | grep -qi "porkbun"; then
        DNS_PROVIDER="Porkbun"

    fi

    echo -e " ${GRAY}DNS Provider:${RESET} ${SKY}$DNS_PROVIDER${RESET}"

else

    warn "No domain was entered."

fi

#=========================================================
# STEP 4
# DOWNLOAD SYSTEM
#=========================================================

seccion "📥 STEP 4  •  INSTALLING ORX TUNNEL"

echo -e "${GRAY}Downloading official system components.${RESET}"
echo

rm -rf "$TMP"
mkdir -p "$TMP"

loading "Downloading ORX Tunnel files"

if ! curl -fsSL --max-time 30 "$MANIFEST_URL" -o "$TMP/manifest.txt"; then
    rm -rf "$TMP"
    error_exit "Could not download the file manifest."
fi

# Normalize manifests served with Windows line endings before building URLs.
sed -i 's/\r$//' "$TMP/manifest.txt"

while IFS= read -r FILE || [[ -n "$FILE" ]]; do
    FILE="${FILE//$'\r'/}"
    [[ -z "$FILE" || "$FILE" == \#* ]] && continue
    mkdir -p "$TMP/$(dirname "$FILE")"
    if ! curl -fsSL --max-time 30 "${BASE_URL}/${FILE}" -o "$TMP/$FILE"; then
        rm -rf "$TMP"
        error_exit "Could not download: $FILE"
    fi
done < "$TMP/manifest.txt"

ok "Files downloaded."

#=========================================================
# BACKUPS
#=========================================================

echo
info "Creating security backups..."

if [[ -f "$BASE/config.conf" ]]; then
    cp "$BASE/config.conf" "$BASE/config.conf.orx-tunnel.backup"
fi

ok "Backups prepared."

#=========================================================
# INSTALL FILES
#=========================================================

mkdir -p "$BASE"

cp -a "$TMP"/. "$BASE"/ || {

    rm -rf "$TMP"

    error_exit "Could not copy files."

}

rm -rf "$TMP"

mkdir -p \
    "$BASE/protocols" \
    "$BASE/users" \
    "$BASE/system" \
    "$BASE/logs"

ok "Files installeds."

#=========================================================
# CONFIGURATION
#=========================================================

cat > "$BASE/config.conf" <<EOF
#=========================================================
# ORX TUNNEL CONFIGURATION
#=========================================================

SERVER_DOMAIN="$SERVER_DOMAIN"
SERVER_IP="$SERVER_IP"

DNS_PROVIDER="$DNS_PROVIDER"

SSL_TUNNEL="$SSL_TUNNEL"
DOMAIN_IP_MATCH="$DOMAIN_IP_MATCH"

PROXY_STATUS="$PROXY_STATUS"

AUTO_START=OFF

#=========================================================
# PROTOCOLS
#=========================================================

OPENSSH=ON
SYSTEMDNS=OFF
WEBSOCKET=OFF
ZIPVPN=OFF
DROPBEAR=OFF
SSL=OFF

BADVPN=OFF
UDP_CUSTOM=OFF
HYSTERIA=OFF

SLOWDNS=OFF
V2RAY=OFF
XRAY=OFF

OPENVPN=OFF
SQUID=OFF
TROJAN=OFF
SHADOWSOCKS=OFF
SOCKS5=OFF

WEBMIN=OFF
FAIL2BAN=ON
BBR=OFF
EOF

#=========================================================
# PERMISOS
#=========================================================

chmod -R 755 "$BASE"
ok "Permisos configureds."

#=========================================================
# COMANDO MENU
#=========================================================

cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash

if [[ -f /etc/orx-tunnel/menu.sh ]]; then
    exec bash /etc/orx-tunnel/menu.sh "$@"
else
    echo "❌ Not found /etc/orx-tunnel/menu.sh"
    exit 1
fi
EOF

chmod +x /usr/local/bin/menu

ok "Comando 'menu' installed."

#=========================================================
# PASO 5
# ROOT
#=========================================================

seccion "👑 PASO 5  •  ACCESO ROOT"

echo -e "${WHITE}You can establecer a password to root.${RESET}"
echo
echo -e "${GREEN}Y${RESET} = Establecer password root"
echo -e "${RED}N${RESET} = Continue sin modificar"
echo

read -r -p "$(echo -e "${GOLD}[Y/N]:${RESET} ")" ROOT_ACCESS

ROOT_ACCESS="$(
    printf '%s' "$ROOT_ACCESS" |
    tr '[:upper:]' '[:lower:]'
)"

if [[ "$ROOT_ACCESS" == "y" ]]; then

    echo
    echo -e "${YELLOW}Enter the new password of root:${RESET}"
    echo

    if passwd root; then

        if [[ -f "$SSHD_CFG" ]]; then

            sed -i \
                -e '/^[[:space:]]*#\?[[:space:]]*PermitRootLogin[[:space:]]/d' \
                -e '/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication[[:space:]]/d' \
                "$SSHD_CFG"

            cat >> "$SSHD_CFG" <<'EOF'

#=========================================================
# ORX Tunnel root access
#=========================================================

PermitRootLogin yes
PasswordAuthentication yes

EOF

            if sshd -t >/dev/null 2>&1; then

                systemctl restart ssh

                ok "Root access enabled."

            else

                fail "La configuration SSH is not valid."

            fi

        fi

    else

        fail "Could not change the password."

    fi

    pausa 2

fi

#=========================================================
# PASO 6
# PROTOCOLS
#=========================================================

seccion "🚀 PASO 6  •  PROTOCOL INSTALLATION"

echo -e "${WHITE}Protocols seleccionados to automatic installation:${RESET}"
echo

echo -e " ${CYAN}◆${RESET} ${WHITE}BadVPN${RESET}"
echo -e " ${PURPLE}◆${RESET} ${WHITE}SSL / TLS${RESET}"
echo -e " ${MAGENTA}◆${RESET} ${WHITE}ZIPVPN${RESET}"
echo -e " ${SKY}◆${RESET} ${WHITE}UDP Hysteria${RESET}"
echo -e " ${GREEN}◆${RESET} ${WHITE}OpenVPN${RESET}"
echo -e " ${GOLD}◆${RESET} ${WHITE}Xray / V2Ray${RESET}"
echo -e " ${PINK}◆${RESET} ${WHITE}Dropbear${RESET}"
echo -e " ${AQUA}◆${RESET} ${WHITE}UDP Custom${RESET}"
echo

pausa 2

if [[ "$INSTALL_PROTOCOLS" == "ON" ]]; then

    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${WHITE}${BOLD}             INSTALANDO PROTOCOLS${RESET}                    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    install_protocolo() {

        local NOMBRE="$1"
        local FILE="$2"

        if [[ -f "$FILE" ]]; then

            echo
            echo -e "${PURPLE}┌──────────────────────────────────────────────────────────────┐${RESET}"
            echo -e "${PURPLE}│${RESET} ${WHITE}📦 $NOMBRE${RESET}"
            echo -e "${PURPLE}└──────────────────────────────────────────────────────────────┘${RESET}"

            if bash "$FILE" --auto; then

                ok "$NOMBRE installed successfully."

            else

                warn "$NOMBRE finished with errors."

            fi

        else

            warn "The module of $NOMBRE."
            echo -e " ${GRAY}$FILE${RESET}"

        fi

    }

    install_protocolo \
        "BadVPN" \
        "$BASE/protocols/badvpn.sh"

    install_protocolo \
        "SSL Tunnel" \
        "$BASE/protocols/ssl.sh"

    install_protocolo \
        "ZIPVPN" \
        "$BASE/protocols/zipvpn.sh"

    install_protocolo \
        "UDP Hysteria" \
        "$BASE/protocols/udphisteria.sh"

    install_protocolo \
        "OpenVPN" \
        "$BASE/protocols/openvpn.sh"

    install_protocolo \
        "V2Ray / Xray" \
        "$BASE/protocols/v2ray.sh"

    install_protocolo \
        "Dropbear" \
        "$BASE/protocols/dropbear.sh"

    install_protocolo \
        "UDP Custom" \
        "$BASE/protocols/udpcustom.sh"

fi

#=========================================================
# BANNER
#=========================================================

cat > /etc/profile.d/orx-tunnel-banner.sh <<'EOF'
#!/bin/bash

[[ $- != *i* ]] && return

SERVER="$(hostname)"
DOMAIN="-"

if [[ -f /etc/orx-tunnel/config.conf ]]; then

    source /etc/orx-tunnel/config.conf

    DOMAIN="${SERVER_DOMAIN:--}"

fi

UPTIME="$(
    uptime -p 2>/dev/null |
    sed 's/up //'
)"

FECHA="$(date '+%d-%m-%Y')"
HORA="$(date '+%H:%M:%S')"

echo
echo -e "\e[1;96m╔══════════════════════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;96m║\e[0m              \e[1;95m🚀 ORX TUNNEL MULTI SCRIPT 🚀\e[0m              \e[1;96m║\e[0m"
echo -e "\e[1;96m╚══════════════════════════════════════════════════════════════╝\e[0m"
echo
echo -e " \e[1;97mServer :\e[0m \e[1;96m$SERVER\e[0m"
echo -e " \e[1;97mDomain  :\e[0m \e[1;95m$DOMAIN\e[0m"
echo -e " \e[1;97mUptime   :\e[0m \e[1;92m$UPTIME\e[0m"
echo -e " \e[1;97mFecha    :\e[0m \e[1;93m$FECHA\e[0m"
echo -e " \e[1;97mHora     :\e[0m \e[1;94m$HORA\e[0m"
echo
echo -e "\e[1;96m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

if [[ "$EUID" -ne 0 ]]; then

    echo -e " 👤 User : $(whoami)"
    echo -e " 🔒 Status  : No eres root"
    echo -e " 👉 Run: \e[1;96msudo -i\e[0m"

else

    echo -e " 👑 User : \e[1;92mroot\e[0m"
    echo -e " 👉 Panel   : \e[1;96mmenu\e[0m"

fi

echo
EOF

chmod +x /etc/profile.d/orx-tunnel-banner.sh

#=========================================================
# FINAL
#=========================================================

titulo

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET} ${WHITE}${BOLD}             🎉 INSTALLATION COMPLETED 🎉${RESET}             ${GREEN}║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo

echo -e " ${GREEN}●${RESET} ${WHITE}Server:${RESET} ${CYAN}LISTO${RESET}"

echo

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD}                 VPS INFORMATION${RESET}                   ${PURPLE}║${RESET}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${PURPLE}║${RESET} ${GRAY}Domain:${RESET} ${SKY}${SERVER_DOMAIN:-Not configured}${RESET}"
echo -e "${PURPLE}║${RESET} ${GRAY}IP     :${RESET} ${CYAN}${SERVER_IP}${RESET}"
echo -e "${PURPLE}║${RESET} ${GRAY}DNS    :${RESET} ${MAGENTA}${DNS_PROVIDER}${RESET}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo

echo
echo -e "${GOLD}🚀 ORX Tunnel Multi Script is ready.${RESET}"
echo

echo -e "${YELLOW}Restart the server now? [Y/N]${RESET}"

read -r -p "$(echo -e "${CYAN}[Y/N]:${RESET} ")" REBOOT_SERVER

REBOOT_SERVER="$(
    printf '%s' "$REBOOT_SERVER" |
    tr '[:upper:]' '[:lower:]'
)"

if [[ "$REBOOT_SERVER" == "y" ]]; then

    echo
    echo -e "${YELLOW}🔄 Restarting en 5 segundos...${RESET}"

    for i in 5 4 3 2 1; do
        echo -ne "\r${CYAN}Reinicio en ${WHITE}${i}${CYAN}...${RESET}"
        sleep 1
    done

    echo
    reboot

else

    echo
    echo -e "${GREEN}✅ Installation completed sin restart.${RESET}"
    echo
    echo -e "${CYAN}👉 Type ${WHITE}menu${CYAN} to abrir el panel.${RESET}"
    echo

fi

exit 0
