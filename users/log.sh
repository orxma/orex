#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Log of Connections SSH
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

while true; do

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}                    📊 LOG OF CONNECTIONS SSH 📊                      ${CYAN}║${RESET}"
echo -e "${CYAN}╠════╦══════════════════╦══════════════════════╦══════════════════════╣${RESET}"
printf "${CYAN}║${WHITE} %-2s ${CYAN}║ ${WHITE}%-16s ${CYAN}║ ${WHITE}%-20s ${CYAN}║ ${WHITE}%-20s${CYAN}║${RESET}\n" \
"N°" "USER" "FECHA / HORA" "IP ORIGEN"
echo -e "${CYAN}╠════╬══════════════════╬══════════════════════╬══════════════════════╣${RESET}"

TOTAL=0

last -aiw | grep -vE "reboot|shutdown|wtmp begins" | while read -r USER TTY IP MES DIA HORA RESTO
do

[[ "$USER" == "" ]] && continue
[[ "$USER" == "root" ]] && continue

FECHA="$MES $DIA $HORA"

TOTAL=$((TOTAL+1))

printf "${CYAN}║${WHITE} %02d ${CYAN}║ ${GREEN}%-16s ${CYAN}║ ${WHITE}%-20s ${CYAN}║ ${BLUE}%-20s${CYAN}║${RESET}\n" \
"$TOTAL" "$USER" "$FECHA" "$IP"

done

echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}"

echo
echo -e "${YELLOW}Optiones availables:${RESET}"
echo
echo -e "${GREEN}[1]${WHITE} View latest 50 logs"
echo -e "${GREEN}[2]${WHITE} Search user"
echo -e "${GREEN}[3]${WHITE} View latest acceso of a user"
echo -e "${RED}[0]${WHITE} Exit"

echo
read -rp "$(echo -e "${GREEN}Select:${RESET} ")" OP

case "$OP" in

1)
clear
echo -e "${CYAN}══════════ LATEST 50 LOGS ══════════${RESET}"
echo
last -50
echo
read -n1 -s -r -p "Press any key..."
;;

2)

read -rp "User: " USER

clear

echo -e "${CYAN}══════════ HISTORIAL DE $USER ══════════${RESET}"
echo

last "$USER"

echo
read -n1 -s -r -p "Press any key..."
;;

3)

read -rp "User: " USER

clear

echo -e "${CYAN}══════════ LAST ACCESS ══════════${RESET}"
echo

last "$USER" | head -1

echo
read -n1 -s -r -p "Press any key..."
;;

0)
exit
;;

*)
echo
echo -e "${RED}Option invalid.${RESET}"
sleep 2
;;

esac

done
