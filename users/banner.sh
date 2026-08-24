#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Banner SSH / Dropbear
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

#==============================
# CONFIG ORX TUNNEL
#==============================

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

[[ -f "$CONFIG" ]] && source "$CONFIG"

BANNER="/etc/issue.net"
SSHD="/etc/ssh/sshd_config"
DROPBEAR="/etc/default/dropbear"

while true; do

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}            📢 BANNER SSH / DROPBEAR 📢            ${CYAN}║${RESET}"
echo -e "${CYAN}╠════════════════════════════════════════════════════╣${RESET}"

echo -e "${GREEN}[1]${WHITE} Crear new Banner"
echo -e "${BLUE}[2]${WHITE} View Banner current"
echo -e "${YELLOW}[3]${WHITE} Edit Banner"
echo -e "${RED}[4]${WHITE} Delete Banner"
echo -e "${CYAN}[0]${WHITE} Return"

echo
read -rp "$(echo -e "${GREEN}Select an option:${RESET} ")" OP

case "$OP" in

1)

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}               CREATE NEW BANNER                 ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
echo

read -rp "$(echo -e "${GREEN}Name of the Server:${RESET} ")" SERVER
[[ -z "$SERVER" ]] && SERVER="${SERVER_NAME:-ORX Tunnel VPN}"

read -rp "$(echo -e "${GREEN}Texto Promocional:${RESET} ")" PROMO
[[ -z "$PROMO" ]] && PROMO="🔥 Welcome a $SERVER 🔥"

read -rp "$(echo -e "${GREEN}Channel Telegram (ej. @ORX Tunnel):${RESET} ")" CHANNEL

read -rp "$(echo -e "${GREEN}Soporte (ej. @KevinSupport):${RESET} ")" SUPPORT

cat > "$BANNER" <<EOF
<html>

<center>
<font color="#00ff00"><b>$SERVER</b></font><br>
<font color="#29b6f6">══════════════════════</font><br><br>

<font color="#ffffff">$PROMO</font><br><br>

<font color="#ffff00">📢 Channel: $CHANNEL</font><br>
<font color="#00ffff">👤 Soporte: $SUPPORT</font><br><br>

<font color="#29b6f6">══════════════════════</font><br>
<font color="#00ff00">Gracias by usar nuestros services</font>

</center>

</html>
EOF

# Configurar OpenSSH
if grep -q "^Banner" "$SSHD"; then
    sed -i "s|^Banner.*|Banner $BANNER|" "$SSHD"
else
    echo "Banner $BANNER" >> "$SSHD"
fi

# Configurar Dropbear
if [[ -f "$DROPBEAR" ]]; then
    if grep -q "^DROPBEAR_BANNER=" "$DROPBEAR"; then
        sed -i "s|^DROPBEAR_BANNER=.*|DROPBEAR_BANNER=\"$BANNER\"|" "$DROPBEAR"
    else
        echo "DROPBEAR_BANNER=\"$BANNER\"" >> "$DROPBEAR"
    fi
fi

systemctl restart ssh 2>/dev/null
systemctl restart sshd 2>/dev/null
systemctl restart dropbear 2>/dev/null

echo
echo -e "${GREEN}✔ Banner created successfully.${RESET}"
sleep 2
;;

2)

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}                 BANNER CURRENT                    ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
echo

if [[ -f "$BANNER" ]]; then

    echo -e "${GREEN}Ruta:${RESET} $BANNER"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo

    cat "$BANNER"

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

else

    echo -e "${RED}Does not exist any banner created.${RESET}"

fi

echo
read -n1 -s -r -p "Press any key to return..."

;;

3)

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}                 EDITAR BANNER                    ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
echo

# If the banner does not exist, create a basic one
if [[ ! -f "$BANNER" ]]; then

cat > "$BANNER" <<EOF
<html>

<center>

<font color="#00ff00"><b>${SERVER_NAME:-ORX Tunnel VPN}</b></font><br>
<font color="#ffffff">Welcome a nuestro server</font>

</center>

</html>
EOF

fi

# Verificar que is not installed
if ! command -v nano >/dev/null 2>&1; then
    echo -e "${RED}Nano is not installed.${RESET}"
    sleep 2
    break
fi

# Abrir editor
nano "$BANNER"

# Configurar OpenSSH
if grep -q "^Banner" "$SSHD"; then
    sed -i "s|^Banner.*|Banner $BANNER|" "$SSHD"
else
    echo "Banner $BANNER" >> "$SSHD"
fi

# Configurar Dropbear
if [[ -f "$DROPBEAR" ]]; then
    if grep -q "^DROPBEAR_BANNER=" "$DROPBEAR"; then
        sed -i "s|^DROPBEAR_BANNER=.*|DROPBEAR_BANNER=\"$BANNER\"|" "$DROPBEAR"
    else
        echo "DROPBEAR_BANNER=\"$BANNER\"" >> "$DROPBEAR"
    fi
fi

# Restart services
systemctl restart ssh 2>/dev/null
systemctl restart sshd 2>/dev/null
systemctl restart dropbear 2>/dev/null

echo
echo -e "${GREEN}✔ Banner updated successfully.${RESET}"
sleep 2

;;

4)

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}               DELETE BANNER                    ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
echo

if [[ ! -f "$BANNER" ]]; then
    echo -e "${RED}Does not exist any banner to delete.${RESET}"
    sleep 2
    continue
fi

read -rp "$(echo -e "${YELLOW}Do you want to delete the banner? [Y/N]: ${RESET}")" RESP

case "$RESP" in

s|S|y|Y|Yes|yes)

    # Delete banner file
    rm -f "$BANNER"

    # Delete configuration of OpenSSH
    sed -i '/^Banner /d' "$SSHD"

    # Delete configuration of Dropbear
    if [[ -f "$DROPBEAR" ]]; then
        sed -i '/^DROPBEAR_BANNER=/d' "$DROPBEAR"
    fi

    # Restart services
    systemctl restart ssh 2>/dev/null
    systemctl restart sshd 2>/dev/null
    systemctl restart dropbear 2>/dev/null

    echo
    echo -e "${GREEN}✔ Banner deleted successfully.${RESET}"
    ;;

*)

    echo
    echo -e "${YELLOW}Operation cancelled.${RESET}"
    ;;

esac

sleep 2

;;

0)
break
;;

*)
echo
echo -e "${RED}Option invalid.${RESET}"
sleep 2
;;

esac

done
