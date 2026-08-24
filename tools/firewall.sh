#!/bin/bash

BASE="/etc/orx-tunnel"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

abrir(){

read -rp "Port: " PORT

ufw allow "$PORT"

echo ""
echo -e "${GREEN}✅ Port $PORT opened.${RESET}"

sleep 2

}

cerrar(){

read -rp "Port: " PORT

ufw delete allow "$PORT"

echo ""
echo -e "${GREEN}✅ Port $PORT closed.${RESET}"

sleep 2

}

estado(){

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}            🔥 FIREWALL${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

ufw status numbered

echo ""
read -n1 -r -p "Press any key..."

}

while true
do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}            🔥 FIREWALL${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo ""
echo " [1] ➮ Open Port"
echo " [2] ➮ Close Port"
echo " [3] ➮ Firewall Status"
echo ""
echo " [0] ➮ Return"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

read -rp " ► Option: " OP

case "$OP" in

1)
abrir
;;

2)
cerrar
;;

3)
estado
;;

0)
exec bash "$BASE/tools/menu.sh"
;;

*)
echo ""
echo -e "${RED}❌ Invalid option.${RESET}"
sleep 2
;;

esac

done
