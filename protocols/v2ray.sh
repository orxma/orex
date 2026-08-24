#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Xray Manager
# Part 1 - Installation
#==================================================

GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
CYAN="\e[1;96m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"
RESET="\e[0m"

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

XRAY_DIR="/usr/local/etc/xray"
XRAY_CFG="$XRAY_DIR/config.json"
XRAY_LOG="/var/log/xray/access.log"

#==================================================
# Dependencias
#==================================================

install_xray_dependencies() {

    echo -e "${CYAN}➜ Updating repositories...${RESET}"
    apt-get update -y

    echo -e "${CYAN}➜ Installing dependencies...${RESET}"

    apt-get install -y \
        curl \
        wget \
        unzip \
        jq \
        socat \
        cron \
        bash-completion

}

#==================================================
# Install Core
#==================================================

install_xray_core() {

    echo -e "${CYAN}➜ Downloading Xray Core...${RESET}"

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    if [[ $? != 0 ]]; then
        echo -e "${RED}✘ Error installing Xray.${RESET}"
        return 1
    fi

    echo -e "${GREEN}✔ Xray installed.${RESET}"

}

#==================================================
# Crear Directorios
#==================================================

create_xray_dirs() {

    mkdir -p "$XRAY_DIR"
    mkdir -p /var/log/xray

    touch "$XRAY_LOG"

}

#==================================================
# Configuration Base
#==================================================

create_xray_config() {

cat > "$XRAY_CFG" <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log"
  },

  "inbounds": [

    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vmess",

      "settings": {
        "clients": []
      },

      "streamSettings": {
        "network": "ws",

        "wsSettings": {
          "path": "/vmess"
        }
      },

      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }

    }

  ],

  "outbounds": [

    {
      "protocol":"freedom",
      "tag":"direct"
    },

    {
      "protocol":"blackhole",
      "tag":"block"
    }

  ]

}
EOF

}

#==================================================
# Resiliencia
#==================================================

ensure_xray_resilience() {

mkdir -p /etc/systemd/system/xray.service.d

cat >/etc/systemd/system/xray.service.d/10-resilience.conf <<EOF
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
Restart=always
RestartSec=3
StartLimitIntervalSec=0
EOF

systemctl daemon-reload

systemctl enable xray >/dev/null 2>&1

}

#==================================================
# Restart
#==================================================

restart_xray() {

    systemctl restart xray

    sleep 2

    if systemctl is-active --quiet xray
    then
        echo -e "${GREEN}✔ Xray iniciado successfully.${RESET}"
    else
        echo -e "${RED}✘ Could not start Xray.${RESET}"
    fi

}

#==================================================
# Install
#==================================================

install_xray() {

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}        INSTALANDO XRAY CORE${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    install_xray_dependencies || return

    install_xray_core || return

    create_xray_dirs

    create_xray_config

    ensure_xray_resilience

    restart_xray

    if [[ -f "$CONFIG" ]]; then

        sed -i '/^XRAY=/d' "$CONFIG"

        echo "XRAY=ON" >> "$CONFIG"

    fi

    echo
    echo -e "${GREEN}✔ Installation completed.${RESET}"

}

#==================================================
# Uninstall
#==================================================

remove_xray() {

    systemctl stop xray 2>/dev/null

    systemctl disable xray 2>/dev/null

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

    rm -rf "$XRAY_DIR"

    rm -rf /var/log/xray

    if [[ -f "$CONFIG" ]]; then

        sed -i '/^XRAY=/d' "$CONFIG"

        echo "XRAY=OFF" >> "$CONFIG"

    fi

    echo -e "${GREEN}✔ Xray deleted.${RESET}"

}
#==================================================
# ORX Tunnel Multi Script
# Xray Manager
# Part 2 - Management of Users VMess
#==================================================

#--------------------------------------------------
# Loadr Domain
#--------------------------------------------------

load_domain() {

    [[ -f "$CONFIG" ]] && source "$CONFIG"

    DOMAIN="${SERVER_DOMAIN:-$DOMAIN}"

    if [[ -z "$DOMAIN" && -f /etc/xray/domain ]]; then
        DOMAIN=$(cat /etc/xray/domain)
    fi

}

#--------------------------------------------------
# Verificar Config
#--------------------------------------------------

check_xray_config() {

    if [[ ! -f "$XRAY_CFG" ]]; then
        echo -e "${RED}✘ Does not exist config.json${RESET}"
        return 1
    fi

    command -v jq >/dev/null 2>&1 || {
        echo -e "${RED}✘ jq is not installed.${RESET}"
        return 1
    }

}

#--------------------------------------------------
# Crear User
#--------------------------------------------------

create_vmess_user() {

    check_xray_config || return

    load_domain

    echo
    read -rp "User : " USERNAME
USERNAME=$(echo "$USERNAME" | xargs)

if [[ -z "$USERNAME" ]]; then
    echo -e "${RED}✘ User invalid.${RESET}"
    return
fi

if vmess_user_exists "$USERNAME"; then
    echo -e "${RED}✘ El user already exists.${RESET}"
    read -n1 -r -p "Press any key to continue..."
    return
fi

    UUID=$(cat /proc/sys/kernel/random/uuid)

    jq \
        --arg uuid "$UUID" \
        --arg email "$USERNAME" \
        '.inbounds[0].settings.clients +=
        [{
            "id":$uuid,
            "level":0,
            "email":$email
        }]' \
        "$XRAY_CFG" > /tmp/xray.json

if ! jq empty /tmp/xray.json >/dev/null 2>&1; then
    echo -e "${RED}✘ Failed to generar config.json.${RESET}"
    rm -f /tmp/xray.json
    return
fi
    mv /tmp/xray.json "$XRAY_CFG"

    systemctl restart xray

    VMESS_UUID="$UUID"
    VMESS_USER="$USERNAME"

    echo
    echo -e "${GREEN}✔ User created successfully.${RESET}"

}

#--------------------------------------------------
# Delete User
#--------------------------------------------------

remove_vmess_user() {

    check_xray_config || return

    echo
    read -rp "User : " USERNAME

    [[ -z "$USERNAME" ]] && return

    jq \
      --arg email "$USERNAME" \
      '.inbounds[0].settings.clients |=
      map(select(.email != $email))' \
      "$XRAY_CFG" > /tmp/xray.json

    mv /tmp/xray.json "$XRAY_CFG"

    systemctl restart xray

    echo
    echo -e "${GREEN}✔ User deleted.${RESET}"

}

#--------------------------------------------------
# Search UUID
#--------------------------------------------------

get_vmess_uuid() {

    jq -r \
    --arg email "$1" \
    '.inbounds[0].settings.clients[]
    | select(.email==$email)
    | .id' \
    "$XRAY_CFG"

}

#--------------------------------------------------
# Listr Users
#--------------------------------------------------

list_vmess_users() {

    check_xray_config || return

    echo
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                  👥 USERS VMESS                        ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════╦══════════════════════╦═══════════════════════════════╣${RESET}"

    printf "${CYAN}║${WHITE} %-2s ${CYAN}║${WHITE} %-20s ${CYAN}║${WHITE} %-29s ${CYAN}║${RESET}\n" "#" "USER" "UUID"

    echo -e "${CYAN}╠════╬══════════════════════╬═══════════════════════════════╣${RESET}"

    TOTAL=0

    while read -r USER
    do

        [[ -z "$USER" ]] && continue

        UUID=$(get_vmess_uuid "$USER")

        SHORT_UUID="${UUID:0:29}..."

        TOTAL=$((TOTAL+1))

        printf "${CYAN}║${GREEN} %-2s ${CYAN}║${WHITE} %-20s ${CYAN}║${YELLOW} %-29s ${CYAN}║${RESET}\n" \
            "$TOTAL" "$USER" "$SHORT_UUID"

    done < <(
        jq -r '.inbounds[0].settings.clients[].email' "$XRAY_CFG"
    )

    if [[ "$TOTAL" == "0" ]]; then

        echo -e "${CYAN}║${RED}              NO EXISTEN USERS REGISTRADOS              ${CYAN}║${RESET}"
        TOTAL=0

    fi

    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    printf "${CYAN}║${WHITE} Total of users : ${GREEN}%-34s${CYAN}║${RESET}\n" "$TOTAL"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"

    echo
    read -n1 -r -p "Press any key to continue..."

}

#--------------------------------------------------
# Existe User
#--------------------------------------------------

vmess_user_exists() {

    jq -e \
    --arg email "$1" \
    '.inbounds[0].settings.clients | any(.email == $email)' \
    "$XRAY_CFG" >/dev/null 2>&1

}
#==================================================
# ORX Tunnel Multi Script
# Xray Manager
# Part 3 - VMess Link e Information
#==================================================

#--------------------------------------------------
# Base64 sin saltos of line
#--------------------------------------------------

base64_encode() {

    if base64 --help 2>/dev/null | grep -q "\-w"
    then
        base64 -w 0
    else
        base64 | tr -d '\n'
    fi

}

#--------------------------------------------------
# Generar Link VMess
#--------------------------------------------------

generate_vmess_link() {

    load_domain

    local USER="$1"
    local UUID="$2"

cat <<EOF | base64_encode
{
  "v":"2",
  "ps":"$USER",
  "add":"$DOMAIN",
  "port":"443",
  "id":"$UUID",
  "aid":"0",
  "scy":"auto",
  "net":"ws",
  "type":"none",
  "host":"$DOMAIN",
  "path":"/vmess",
  "tls":"tls",
  "sni":"$DOMAIN",
  "alpn":""
}
EOF

}

#--------------------------------------------------
# Show User
#--------------------------------------------------

show_vmess_user() {

    load_domain

    local USER="$1"
    local UUID="$2"

    LINK="vmess://$(generate_vmess_link "$USER" "$UUID")"

    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                 ✅ CUENTA VMESS CREADA                     ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

    printf "${CYAN}║${RESET} 👤 User    ${WHITE}: %-40s${CYAN}║${RESET}\n" "$USER"
    printf "${CYAN}║${RESET} 🆔 UUID       ${WHITE}: %-40s${CYAN}║${RESET}\n" "$UUID"
    printf "${CYAN}║${RESET} 🌐 Domain    ${WHITE}: %-40s${CYAN}║${RESET}\n" "$DOMAIN"
    printf "${CYAN}║${RESET} 🔒 Port     ${WHITE}: %-40s${CYAN}║${RESET}\n" "443"
    printf "${CYAN}║${RESET} 🛡 Security  ${WHITE}: %-40s${CYAN}║${RESET}\n" "TLS"
    printf "${CYAN}║${RESET} 📡 Network    ${WHITE}: %-40s${CYAN}║${RESET}\n" "WebSocket"
    printf "${CYAN}║${RESET} 📂 Path       ${WHITE}: %-40s${CYAN}║${RESET}\n" "/vmess"

    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${YELLOW}                     🔗 ENLACE VMESS                        ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

    echo
    echo -e "${GREEN}$LINK${RESET}"
    echo

    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

    echo
    read -n1 -r -p "Press any key to continue..."

}

#--------------------------------------------------
# Show User by Name
#--------------------------------------------------

show_vmess_account() {

    check_xray_config || return

    echo
    read -rp "User : " USERNAME

    [[ -z "$USERNAME" ]] && return

    UUID=$(get_vmess_uuid "$USERNAME")

    if [[ -z "$UUID" ]]; then
        echo
        echo -e "${RED}✘ User not found.${RESET}"
        return
    fi

    show_vmess_user "$USERNAME" "$UUID"

}

#--------------------------------------------------
# Crear Account Completa
#--------------------------------------------------

create_vmess_account() {

    create_vmess_user || return

    load_domain
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}✘ No domain is configured.${RESET}"
    return
fi
    LINK="vmess://$(generate_vmess_link "$VMESS_USER" "$VMESS_UUID")"

    clear

    echo
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                 🎉 CUENTA VMESS CREADA EXITOSAMENTE              ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${RESET}"

    printf "${CYAN}║${RESET} 👤 User     ${WHITE}: %-42s${CYAN}║${RESET}\n" "$VMESS_USER"
    printf "${CYAN}║${RESET} 🆔 UUID        ${WHITE}: %-42s${CYAN}║${RESET}\n" "$VMESS_UUID"
    printf "${CYAN}║${RESET} 🌐 Domain     ${WHITE}: %-42s${CYAN}║${RESET}\n" "$DOMAIN"
    printf "${CYAN}║${RESET} 🔒 Port      ${WHITE}: %-42s${CYAN}║${RESET}\n" "443"
    printf "${CYAN}║${RESET} 📡 Network     ${WHITE}: %-42s${CYAN}║${RESET}\n" "WebSocket"
    printf "${CYAN}║${RESET} 🛡 Security   ${WHITE}: %-42s${CYAN}║${RESET}\n" "TLS"
    printf "${CYAN}║${RESET} 📂 Path        ${WHITE}: %-42s${CYAN}║${RESET}\n" "/vmess"

    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${YELLOW}                     🔗 ENLACE VMESS                              ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${RESET}"

    echo
    echo -e "${GREEN}$LINK${RESET}"
    echo

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}✔ The account is ready to use.${RESET}"
    echo -e "${GREEN}✔ Comparta el enlace VMess with el cliente.${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo
    read -n1 -r -p "Press any key to return to the menu..."

}

#--------------------------------------------------
# Exportar Link
#--------------------------------------------------

export_vmess_link() {

    check_xray_config || return

    echo
    read -rp "User : " USERNAME

    [[ -z "$USERNAME" ]] && return

    UUID=$(get_vmess_uuid "$USERNAME")

    [[ -z "$UUID" ]] && {
        echo -e "${RED}✘ User not found.${RESET}"
        return
    }

    LINK="vmess://$(generate_vmess_link "$USERNAME" "$UUID")"

    echo "$LINK" >/tmp/vmess.txt

    echo
    echo -e "${GREEN}✔ Link exportado:${RESET}"
    echo "/tmp/vmess.txt"

}

#--------------------------------------------------
# Information of the Server
#--------------------------------------------------

vmess_server_info() {

    load_domain

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}         VMESS INFORMATION${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo "Domain : $DOMAIN"
    echo "Port  : 443"
    echo "TLS     : Yes"
    echo "Network : ws"
    echo "Path    : /vmess"
    echo "Host    : $DOMAIN"

    echo
read -n1 -r -p "Press any key to continue..."
}
#==================================================
# ORX Tunnel Multi Script
# Xray Manager
# Part 4 - Online, Status y Menu
#==================================================

#--------------------------------------------------
# Users Online
#--------------------------------------------------

xray_online_users() {

    if [[ ! -f "$XRAY_LOG" ]]; then
        echo
        echo -e "${RED}✘ The access.log.${RESET}"
        return
    fi

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}        ONLINE USERS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo

    LIMIT=$(date -d "60 seconds ago" "+%Y/%m/%d %H:%M:%S")

    awk -v LIM="$LIMIT" '
    /email:/ {

        DATA=$1" "$2

        if(DATA>=LIM){

            split($0,a,"email: ")

            print a[2]

        }

    }' "$XRAY_LOG" | sort -u

    TOTAL=$(awk -v LIM="$LIMIT" '
    /email:/ {

        DATA=$1" "$2

        if(DATA>=LIM){

            split($0,a,"email: ")

            print a[2]

        }

    }' "$XRAY_LOG" | sort -u | wc -l)

    echo
    echo -e "${GREEN}Users connected:${RESET} $TOTAL"
    echo
echo
read -n1 -r -p "Press any key to continue..."
}

#--------------------------------------------------
# Restart
#--------------------------------------------------

restart_xray_service() {

    echo

    systemctl restart xray

    sleep 2
if ! systemctl is-active --quiet xray; then
    echo -e "${RED}✘ Xray could not start.${RESET}"
    return
fi

    if systemctl is-active --quiet xray
    then
        echo -e "${GREEN}✔ Xray reiniciado successfully.${RESET}"
    else
        echo -e "${RED}✘ Restart failed Xray.${RESET}"
    fi

}

#--------------------------------------------------
# Status
#--------------------------------------------------

xray_status() {

    echo

    if systemctl is-active --quiet xray; then
        STATUS="${GREEN}🟢 ACTIVE${RESET}"
    else
        STATUS="${RED}🔴 STOPPED${RESET}"
    fi

    VERSION=$(xray version 2>/dev/null | head -1)
    VERSION=${VERSION:-NO INSTALADO}

    if xray run -test -config "$XRAY_CFG" >/dev/null 2>&1; then
        CONFIG_STATUS="${GREEN}🟢 CORRECTA${RESET}"
    else
        CONFIG_STATUS="${RED}🔴 ERROR${RESET}"
    fi

    if ss -lnt | grep -q ":10002 "; then
        PORT10002="${GREEN}🟢 ESCUCHANDO${RESET}"
    else
        PORT10002="${RED}🔴 CERRADO${RESET}"
    fi

    if ss -lnt | grep -q ":443 "; then
        PORT443="${GREEN}🟢 DISPONIBLE${RESET}"
    else
        PORT443="${YELLOW}🟡 Gestionado by HAProxy${RESET}"
    fi

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                 📊 SERVICE STATUS XRAY              ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"

    printf " %-18s %b\n" "Status:" "$STATUS"
    printf " %-18s ${GREEN}%s${RESET}\n" "Version:" "$VERSION"
    printf " %-18s %b\n" "Configuration:" "$CONFIG_STATUS"
    printf " %-18s %b\n" "Port 443:" "$PORT443"
    printf " %-18s %b\n" "Port 10002:" "$PORT10002"

    echo
    echo -e " ${GREEN}🟢${RESET} VMess ............... Available"
    echo -e " ${GREEN}🟢${RESET} WebSocket ........... Available"
    echo -e " ${GREEN}🟢${RESET} TLS ................. Available"
    echo -e " ${GREEN}🟢${RESET} JSON Config ......... Loaddo"

    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"

    echo
    read -n1 -r -p "Press any key to continue..."

}

#--------------------------------------------------
# Menu
#--------------------------------------------------
xray_menu() {

while true
do

clear

source "$CONFIG" 2>/dev/null
load_domain

if systemctl is-active --quiet xray; then
    STATUS="${GREEN}🟢 ACTIVE${RESET}"
else
    STATUS="${RED}🔴 DESINSTALADO${RESET}"
fi

VERSION=$(xray version 2>/dev/null | head -1)
VERSION=${VERSION:-NO INSTALADO}

DOMAIN_SHOW="${DOMAIN:-${SERVER_DOMAIN:-NO CONFIGURADO}}"

TOTAL_USERS=0
ONLINE_USERS=0

if [[ -f "$XRAY_CFG" ]]; then
    TOTAL_USERS=$(jq '.inbounds[0].settings.clients | length' "$XRAY_CFG" 2>/dev/null)
fi

if [[ -f "$XRAY_LOG" ]]; then
    LIMIT=$(date -d "60 seconds ago" "+%Y/%m/%d %H:%M:%S")
    ONLINE_USERS=$(awk -v LIM="$LIMIT" '
    /email:/{
        DATA=$1" "$2
        if(DATA>=LIM){
            split($0,a,"email: ")
            print a[2]
        }
    }' "$XRAY_LOG" | sort -u | wc -l)
fi

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${WHITE}              🚀 ORX Tunnel Multi Script              ${CYAN}║${RESET}"
echo -e "${CYAN}║${WHITE}                 XRAY MANAGER v3.0                  ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"

echo -e "${CYAN}┌──────────────── INFORMATION ────────────────┐${RESET}"
printf " ${WHITE}Status      : %b\n" "$STATUS"
printf " ${WHITE}Domain     : ${GREEN}%s${RESET}\n" "$DOMAIN_SHOW"
printf " ${WHITE}Protocolo   : ${GREEN}VMess + WebSocket + TLS${RESET}\n"
printf " ${WHITE}Port TLS  : ${GREEN}443${RESET}\n"
printf " ${WHITE}Path        : ${GREEN}/vmess${RESET}\n"
printf " ${WHITE}Service    : ${GREEN}Xray Core${RESET}\n"
printf " ${WHITE}Version     : ${GREEN}%s${RESET}\n" "$VERSION"
printf " ${WHITE}Users    : ${GREEN}%s${RESET}\n" "$TOTAL_USERS"
printf " ${WHITE}Online      : ${GREEN}%s${RESET}\n" "$ONLINE_USERS"
echo -e "${CYAN}└─────────────────────────────────────────────┘${RESET}"

echo

if systemctl is-active --quiet xray; then

echo -e "${CYAN}┌────────────── Management of Users ──────────────┐${RESET}"
echo -e " ${GREEN}[1]${RESET} 👤 Crear User VMess"
echo -e " ${GREEN}[2]${RESET} 🗑 Delete User"
echo -e " ${GREEN}[3]${RESET} 📋 Listr Users"
echo -e " ${GREEN}[4]${RESET} 📄 Show Account"
echo -e "${CYAN}└────────────────────────────────────────────────┘${RESET}"

echo

echo -e "${CYAN}┌──────────── Service Management ───────┐${RESET}"
echo -e " ${GREEN}[5]${RESET} 🌐 Users Online"
echo -e " ${GREEN}[6]${RESET} ℹ Information VMess"
echo -e " ${GREEN}[7]${RESET} 🔄 Restart Xray"
echo -e " ${GREEN}[8]${RESET} 📊 Status of the Service"
echo -e " ${GREEN}[9]${RESET} ♻ Reinstall Xray"
echo -e " ${GREEN}[10]${RESET} 🗑 Uninstall Xray"
echo -e "${CYAN}└────────────────────────────────────────────────┘${RESET}"

else

echo -e "${CYAN}┌──────────────── Installation ────────────────┐${RESET}"
echo -e " ${GREEN}[1]${RESET} 🚀 Install Xray Core"
echo -e "${CYAN}└─────────────────────────────────────────────┘${RESET}"

fi

echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e " ${GREEN}[0]${RESET} ↩ Return"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo
read -rp " ► Option: " opc

case "$opc" in

1)
if systemctl is-active --quiet xray; then
    create_vmess_account
else
    install_xray
fi
;;

2)
if systemctl is-active --quiet xray; then
    remove_vmess_user
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

3)
if systemctl is-active --quiet xray; then
    list_vmess_users
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

4)
if systemctl is-active --quiet xray; then
    show_vmess_account
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

5)
if systemctl is-active --quiet xray; then
    xray_online_users
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

6)
if systemctl is-active --quiet xray; then
    vmess_server_info
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

7)
if systemctl is-active --quiet xray; then
    restart_xray_service
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

8)
if systemctl is-active --quiet xray; then
    xray_status
else
    echo "❌ Xray is not installed."
    sleep 2
fi
;;

9)
if systemctl is-active --quiet xray; then
    install_xray
fi
;;

10)
if systemctl is-active --quiet xray; then
    remove_xray
fi
;;

0)
exec bash "$BASE/protocols/menu.sh"
;;

*)
echo
echo "❌ Option invalid."
sleep 2
;;

esac

done

}
#==================================================
# AUTOMATIC MODE
#==================================================

if [[ "$1" == "--auto" ]]; then
    echo "🚀 Installing Xray automatically..."

    if install_xray; then
        echo "✅ Xray installed successfully."
        exit 0
    else
        echo "❌ Error installing Xray."
        exit 1
    fi
fi
#==================================================
# Inicio
#==================================================

xray_menu
