#!/bin/bash

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

source "$CONFIG"

clear

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
WHITE="\e[1;97m"
RESET="\e[0m"

while true; do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${WHITE}            🔐 OPENSSH MANAGER${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [[ "$OPENSSH" == "ON" ]]; then
    STATUS="${GREEN}🟢 ACTIVE${RESET}"
else
    STATUS="${RED}🔴 UNINSTALLED${RESET}"
fi

echo -e " Status     : $STATUS"
echo -e " Port     : 22"
echo -e " Service   : ssh"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [[ "$OPENSSH" == "ON" ]]; then
cat <<EOF
 [1] ➮ Uninstall OpenSSH
 [2] ➮ Restart Service
 [3] ➮ View Status
 [0] ➮ Return
EOF
else
cat <<EOF
 [1] ➮ Install OpenSSH
 [0] ➮ Return
EOF
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
read -rp " ► Option: " OP

case $OP in

1)

if [[ "$OPENSSH" == "ON" ]]; then

echo ""
read -rp "Uninstall OpenSSH? (s/n): " R

[[ "$R" != "s" ]] && continue

apt remove openssh-server -y

sed -i 's/OPENSSH=ON/OPENSSH=OFF/' "$CONFIG"

OPENSSH=OFF

echo ""
echo "✅ OpenSSH desinstalled."

sleep 2

else

apt update

apt install openssh-server -y

systemctl enable ssh

systemctl restart ssh

sed -i 's/OPENSSH=OFF/OPENSSH=ON/' "$CONFIG"

OPENSSH=ON

echo ""
echo "✅ OpenSSH installed."

sleep 2

fi

;;

2)

if [[ "$OPENSSH" == "ON" ]]; then

systemctl restart ssh

echo ""
echo "✅ Service restarted."

sleep 2

fi

;;

3)

if [[ "$OPENSSH" == "ON" ]]; then

systemctl status ssh --no-pager

echo ""

read -n1 -r -p "Press any key..."

fi

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
