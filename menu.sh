#!/bin/bash

#=========================================================
#        ORX TUNNEL MULTI SCRIPT - PREMIUM EDITION
#=========================================================

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

#=========================================================
# Verificar configuration
#=========================================================

[[ ! -f "$CONFIG" ]] && {
    clear
    echo ""
    echo "❌ Not found config.conf"
    echo "👉 Run install.sh first"
    echo ""
    exit 1
}

source "$CONFIG"

grep -q "^OPTIMIZAR=" "$CONFIG" || echo "OPTIMIZAR=OFF" >> "$CONFIG"

source "$CONFIG"

#=========================================================
# Variables
#=========================================================

ZIPVPN=${ZIPVPN:-OFF}
OPTIMIZAR=${OPTIMIZAR:-OFF}
SYSTEMDNS=${SYSTEMDNS:-OFF}
XRAY=${XRAY:-OFF}
CUPSD=${CUPSD:-OFF}
SSL_TUNNEL=${SSL_TUNNEL:-OFF}
CLOUDFLARE_STATUS=${CLOUDFLARE_STATUS:-OFF}
PROXY_STATUS=${PROXY_STATUS:-OFF}
AUTO_START=${AUTO_START:-OFF}

# Count variables (initialized to 0)
SSH_COUNT=${SSH_COUNT:-0}
V2RAY_COUNT=${V2RAY_COUNT:-0}
HYSTERIA_COUNT=${HYSTERIA_COUNT:-0}
OPENVPN_COUNT=${OPENVPN_COUNT:-0}

# Detectar HAProxy
if systemctl is-active --quiet haproxy; then
    SSL="ON"
    SSL_TUNNEL="ON"
else
    SSL="OFF"
    SSL_TUNNEL="OFF"
fi
# Detectar Cloudflare
if [[ -n "$SERVER_DOMAIN" ]]; then
    if dig +short NS "$SERVER_DOMAIN" | grep -qi cloudflare; then
        CLOUDFLARE_STATUS="ON"
    else
        CLOUDFLARE_STATUS="OFF"
    fi
fi
#=========================================================
# COLORES PREMIUM
#=========================================================

RESET="\e[0m"

RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

# Colores adicionales to interface
ORANGE="\e[38;5;214m"
PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
SKY="\e[38;5;117m"
LIME="\e[38;5;154m"
GOLD="\e[38;5;220m"

# Efectos
BOLD="\e[1m"
DIM="\e[2m"
BLINK="\e[5m"

#=========================================================
# VERSION DEL SCRIPT
#=========================================================

VERSION_FILE="$BASE/version.txt"
VERSION_URL="https://sc.orx.ma/version.txt"

# Version installed
if [[ -f "$VERSION_FILE" ]]; then
    VERSION_CURRENT=$(head -n1 "$VERSION_FILE" | tr -d '\r')
else
    VERSION_CURRENT="v2.0"
fi

# Consultar version available en GitHub
NEW_VERSION=$(curl -fsSL --max-time 5 "$VERSION_URL" 2>/dev/null | head -n1 | tr -d '\r')

[[ -z "$NEW_VERSION" ]] && NEW_VERSION="No available"
#=========================================================
# Information VPS
#=========================================================

OS=$(source /etc/os-release && echo "$NAME $VERSION_ID")
CPU=$(nproc)
IP=$(hostname -I | awk '{print $1}')

TOTAL_RAM=$(free -h | awk '/Mem:/ {print $2}')
USED_RAM=$(free -h | awk '/Mem:/ {print $3}')
FREE_RAM=$(free -h | awk '/Mem:/ {print $7}')

RAM_USE=$(free | awk '/Mem:/ {printf("%.0f"),$3/$2*100}')
CPU_USE=$(top -bn1 | grep -i "cpu" | head -1 | awk '{print int($2+$4)}')

DISK=$(df -h / | awk 'NR==2 {print $5}')

UPTIME=$(uptime -p | sed 's/up //')

#=========================================================
# MAIN MENU
#=========================================================

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET} ${BOLD}${WHITE}             ORX TUNNEL CONTROL PANEL${RESET}             ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET} ${GRAY}                  PREMIUM EDITION${RESET}                  ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo ""
echo -e " ${GOLD}◆${RESET} ${YELLOW}OS${RESET}      ${GRAY}:${RESET} ${WHITE}$OS${RESET}"
echo -e " ${GOLD}◆${RESET} ${YELLOW}UPTIME${RESET}  ${GRAY}:${RESET} ${WHITE}$UPTIME${RESET}"
echo -e " ${GOLD}◆${RESET} ${YELLOW}IP/DOM${RESET}  ${GRAY}:${RESET} ${SKY}$IP${RESET} ${GRAY}/${RESET} ${PINK}${SERVER_DOMAIN:-sin-domain}${RESET}"
echo -e " ${GOLD}◆${RESET} ${YELLOW}DISK${RESET}   ${GRAY}:${RESET} ${WHITE}$DISK used${RESET}"
echo -e " ${GOLD}◆${RESET} ${YELLOW}CPU${RESET}     ${GRAY}:${RESET} ${LIME}${CPU_USE}%${RESET} ${GRAY}|${RESET} ${WHITE}Cores: $CPU${RESET}"
echo -e " ${GOLD}◆${RESET} ${YELLOW}RAM${RESET}     ${GRAY}:${RESET} ${LIME}${USED_RAM}/${TOTAL_RAM}${RESET} ${GRAY}|${RESET} ${WHITE}Free: $FREE_RAM${RESET}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e " ${MAGENTA}${BOLD}◆ ACTIVE PROTOCOLS${RESET}"
echo ""

[[ "$OPENSSH" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}SSH${RESET}            ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(22)${RESET}"

[[ "$DROPBEAR" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}Dropbear${RESET}       ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(${DROPBEAR_PORT:-90})${RESET}"

[[ "$SSL" == "ON" || "$SSL_TUNNEL" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}SSL Tunnel${RESET}     ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(80,443,8080)${RESET}"

[[ "$ZIPVPN" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}ZiVPN${RESET}          ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(${ZIPVPN_PORT:-Unknown})${RESET}"

[[ "$BADVPN" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}BadVPN${RESET}         ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(7200,7300)${RESET}"

[[ "$UDP_CUSTOM" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}UDP Custom${RESET}     ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(36712)${RESET}"

[[ "$SLOWDNS" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}SlowDNS${RESET}        ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(53)${RESET}"

[[ "$XRAY" == "ON" ]] && \
echo -e "   ${GREEN}●${RESET} ${WHITE}Xray/V2Ray${RESET}     ${GRAY}:${RESET} ${GREEN}${BOLD}ON${RESET} ${GRAY}(443)${RESET}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo -e " ${BLUE}${BOLD}◆ CUENTAS${RESET} ${GRAY}:${RESET} SSH:${WHITE}${SSH_COUNT}${RESET}  V2Ray:${WHITE}${V2RAY_COUNT}${RESET}  Histeria:${WHITE}${HYSTERIA_COUNT}${RESET}  OpenVPN:${WHITE}${OPENVPN_COUNT}${RESET}"

echo -e " ${BLUE}${BOLD}◆ STATUS ${RESET} ${GRAY}:${RESET} SSH:${GREEN}${OPENSSH:-OFF}${RESET}  V2Ray:${GREEN}${XRAY:-OFF}${RESET}  Histeria:${GREEN}${HYSTERIA:-OFF}${RESET}  OpenVPN:${GREEN}${OPENVPN:-OFF}${RESET}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo -e " ${GOLD}${BOLD}[01]${RESET} ${WHITE}👥 Users SSH${RESET}        ${GOLD}${BOLD}[05]${RESET} ${WHITE}📦 Install protocols${RESET}"
echo -e " ${GOLD}${BOLD}[02]${RESET} ${WHITE}🛩️ Optimize VPS${RESET}       ${GOLD}${BOLD}[06]${RESET} ${WHITE}🔄 Update / Remove${RESET}"
echo -e " ${GOLD}${BOLD}[03]${RESET} ${WHITE}🌐 Change domain${RESET}     ${GOLD}${BOLD}[00]${RESET} ${WHITE}🚪 Exit${RESET}"
echo -e " ${GOLD}${BOLD}[04]${RESET} ${WHITE}⚒️ Auto reboot${RESET}"

echo -e "${CYAN}────────────────────────────────────────────────${RESET}"

if [[ "$NEW_VERSION" != "No available" && "$NEW_VERSION" != "$VERSION_CURRENT" ]]; then

    echo -e "${YELLOW}  ⚡ NEW VERSION DISPONIBLE: ${GREEN}${NEW_VERSION}${RESET}"
    echo -e "${GRAY}  Version installed: ${WHITE}${VERSION_CURRENT}${RESET}"

else

    echo -e "${GREEN}  ✔ SISTEMA UPDATED${RESET}"
    echo -e "${GRAY}  Version: ${WHITE}${VERSION_CURRENT}${RESET}"

fi

echo -e "${CYAN}────────────────────────────────────────────────${RESET}"
echo -e "${WHITE}         ORX Tunnel Multi Script${RESET}"
echo -e "${GRAY}              Premium Edition${RESET}"
echo -e "${CYAN}────────────────────────────────────────────────${RESET}"

echo ""
echo -ne "${CYAN}${BOLD}➜${RESET} ${WHITE}Select an option ${GRAY}➤${RESET} "
read -r OPCION
#=========================================================
# CASE PRINCIPAL
#=========================================================

case "$OPCION" in
1)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                 👥 CREATING USERS                      ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ -f "$BASE/users/menu.sh" ]]; then

    bash "$BASE/users/menu.sh"

else

    echo -e "${RED}❌ The module of users is not installed.${RESET}"
    sleep 2
    exec bash "$BASE/menu.sh"

fi

;;

#=========================================================

2)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                    🚀 OPTIMIZE VPS                           ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ -f "$BASE/tools/optimize.sh" ]]; then

    bash "$BASE/tools/optimize.sh"

else

    echo -e "${RED}❌ optimize.sh not found.${RESET}"
    sleep 2

fi

exec bash "$BASE/menu.sh"

;;
#=========================================================

3)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                  🌐 CHANGE DOMAIN                         ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ -f "$BASE/tools/change-domain" ]]; then

    bash "$BASE/tools/change-domain"

else

    echo -e "${RED}❌ change-domain not found.${RESET}"
    sleep 2

fi

exec bash "$BASE/menu.sh"

;;
#=========================================================

4)

FILE="/etc/profile.d/orx-tunnel.sh"

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                    🔄 AUTO START                           ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ "$AUTO_START" == "OFF" ]]; then

    sed -i 's/AUTO_START=OFF/AUTO_START=ON/' "$CONFIG"

cat > "$FILE" <<'EOF'
#!/bin/bash
if [[ $- == *i* ]]; then
    menu
fi
EOF

    chmod +x "$FILE"

    echo -e "${GREEN}✅ Auto reboot activated successfully.${RESET}"

else

    sed -i 's/AUTO_START=ON/AUTO_START=OFF/' "$CONFIG"

    rm -f "$FILE"

    echo -e "${YELLOW}⚠️ Auto reboot desactivated.${RESET}"

fi

sleep 2
exec bash "$BASE/menu.sh"

;;

#=========================================================

5)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                📦 PROTOCOL INSTALLER                  ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ -f "$BASE/protocols/menu.sh" ]]; then

    bash "$BASE/protocols/menu.sh"

elif [[ -f "$HOME/multi-script/protocols/menu.sh" ]]; then

    mkdir -p "$BASE/protocols"

    cp -rf "$HOME/multi-script/protocols/menu.sh" \
    "$BASE/protocols/menu.sh"

    chmod +x "$BASE/protocols/menu.sh"

    bash "$BASE/protocols/menu.sh"

else

    echo -e "${RED}❌ Protocol menu not found.${RESET}"

    sleep 2

    exec bash "$BASE/menu.sh"

fi

;;

#=========================================================

6)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                    🛠 UPDATE / REMOVE                        ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo ""
echo -e "${YELLOW}[1]${WHITE} 🗑 Remoview Script"
echo -e "${YELLOW}[2]${WHITE} 🔄 Update Script"
echo ""

read -rp "$(echo -e "${CYAN}➜ Select an option ${WHITE}➤ ${RESET}")" OP6

case "$OP6" in

1)

clear

echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}║                  ⚠️ DELETE SCRIPT                         ║${RESET}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

echo -e "${YELLOW}[1]${WHITE} 🗑 Delete ORX Tunnel Multi Script"
echo -e "${YELLOW}[2]${WHITE} ♻️ Reinstall VPS"
echo -e "${YELLOW}[0]${WHITE} 🔙 Return"
echo ""

read -rp "$(echo -e "${CYAN}➜ Select an option ${WHITE}➤ ${RESET}")" OPDEL

case "$OPDEL" in

1)

clear

echo -e "${RED}⚠️ Deleting ORX Tunnel Multi Script...${RESET}"

sleep 1

rm -rf /etc/orx-tunnel
rm -f /usr/local/bin/menu
rm -f /etc/profile.d/orx-tunnel.sh

echo ""
echo -e "${GREEN}✅ Script deleted successfully.${RESET}"
echo -e "${GREEN}🧹 System cleaned successfully.${RESET}"

sleep 3

exit

;;

2)

clear

echo -e "${YELLOW}♻️ Starting rebuild of the VPS...${RESET}"

cd /root || exit

wget https://raw.githubusercontent.com/oktaviaps/rebuild-vps/main/uinstal; chmod 777 *; ./uinstal

;;

0)

exec menu

;;

*)

echo -e "${RED}❌ Option invalid.${RESET}"

sleep 2

exec menu

;;

esac

;;

#=========================================================
2)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET} ${WHITE}${BOLD}                 🔄 UPDATING SCRIPT${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo ""
echo -e "${CYAN}◆${RESET} ${WHITE}Preparing update...${RESET}"
echo ""

UPDATE="/etc/orx-tunnel/update.sh"

if [[ ! -f "$UPDATE" ]]; then

    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}❌ Not found update.sh${RESET}                            ${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"

    echo ""
    echo -e "${YELLOW}Expected location:${RESET}"
    echo -e " ${GRAY}➜${RESET} ${WHITE}$UPDATE${RESET}"

    sleep 3
    exec menu

fi

chmod +x "$UPDATE"

echo -e "${CYAN}◆${RESET} ${WHITE}Running updater...${RESET}"
echo ""

bash "$UPDATE"

STATUS=$?

echo ""

if [[ $STATUS -eq 0 ]]; then

    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET} ${WHITE}${BOLD}        ✅ UPDATE COMPLETED SUCCESSFULLY${RESET}      ${GREEN}║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"

else

    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}              ❌ UPDATE ERROR${RESET}             ${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"

fi

echo ""
echo -e "${CYAN}🚀${RESET} ${WHITE}Returning to the panel...${RESET}"

sleep 2

exec menu

;;

esac

;;

#=========================================================

0)

clear

echo ""
echo -e "${GREEN}👋 Thank you for using ORX Tunnel Multi Script Premium.${RESET}"
echo ""

exit

;;

#=========================================================

*)

echo ""

echo -e "${RED}❌ Option invalid.${RESET}"

sleep 1

exec bash "$BASE/menu.sh"

;;

esac
