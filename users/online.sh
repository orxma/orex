#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Users SSH Online v2
#==================================================

GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
CYAN="\e[1;96m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}              👁 ONLINE USERS 👁              ${CYAN}║${RESET}"
echo -e "${CYAN}╠════╦════════════════════╦═══════════════════════╣${RESET}"

printf "${CYAN}║${WHITE} %-2s ${CYAN}║ ${WHITE}%-18s ${CYAN}║ ${WHITE}%-21s${CYAN}║${RESET}\n" \
"ID" "USER" "CONNECTIONS"

echo -e "${CYAN}╠════╬════════════════════╬═══════════════════════╣${RESET}"

TOTAL=0
ID=1

declare -A USERS
#==================================================
# CONTAR USERS SSH CONECTADOS
#==================================================

while read -r USER; do

    [[ -z "$USER" ]] && continue
[[ "$USER" == "root" ]] && continue
[[ "$USER" == "unknown" ]] && continue
[[ "$USER" == "invalid" ]] && continue
[[ "$USER" == "(null)" ]] && continue

    ((USERS["$USER"]++))

done < <(

ps -C sshd -o args= | \
grep "\[priv\]" | \
awk -F'sshd: ' '{print $2}' | \
awk '{print $1}'

)
#==================================================
# MOSTRAR USERS
#==================================================

for USER in $(printf "%s\n" "${!USERS[@]}" | sort); do

    CONN=${USERS[$USER]}

    printf "${CYAN}║${WHITE} %02d ${CYAN}║ ${GREEN}%-18s ${CYAN}║ ${YELLOW}%-21s${CYAN}║${RESET}\n" \
    "$ID" "$USER" "$CONN"

    ((TOTAL++))
    ((ID++))

done

if [[ $TOTAL -eq 0 ]]; then

    echo -e "${CYAN}║${RED} There are no users connected.                  ${CYAN}║${RESET}"

fi

echo -e "${CYAN}╠════╩════════════════════╩═══════════════════════╣${RESET}"
echo -e "${WHITE} Users Online : ${GREEN}$TOTAL${RESET}"
echo -e "${WHITE} Updated     : ${GREEN}$(date '+%d/%m/%Y %H:%M:%S')${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"

echo
read -n1 -s -r -p "Press any key to return..."
