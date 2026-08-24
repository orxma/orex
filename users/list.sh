#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# User List SSH
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

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}                      📋 USERS REGISTRADOS SSH 📋                      ${CYAN}║${RESET}"
echo -e "${CYAN}╠════╦══════════════════╦══════════════╦════════╦══════════════════════════╣${RESET}"
printf "${CYAN}║${WHITE} %-2s ${CYAN}║ ${WHITE}%-16s ${CYAN}║ ${WHITE}%-12s ${CYAN}║ ${WHITE}%-6s ${CYAN}║ ${WHITE}%-24s${CYAN}║${RESET}\n" \
"N°" "USER" "EXPIRES" "DAYS" "STATUS"
echo -e "${CYAN}╠════╬══════════════════╬══════════════╬════════╬══════════════════════════╣${RESET}"

TOTAL=0
ACTIVES=0
EXPIRESDOS=0

for USER in $(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd); do

EXPIRES=$(chage -l "$USER" | awk -F': ' '/Account expires/{print $2}')

if [[ "$EXPIRES" == "never" ]]; then
    FECHA="Nunca"
    DIAS="∞"
    STATUS="${GREEN}Active${RESET}"
    ((ACTIVES++))
else
    FECHA=$(date -d "$EXPIRES" +%Y-%m-%d 2>/dev/null)

    HOY=$(date +%s)
    FIN=$(date -d "$FECHA" +%s)

    REST=$(( (FIN - HOY) / 86400 ))

    if [[ $REST -lt 0 ]]; then
        DIAS="0"
        STATUS="${RED}Expiresdo${RESET}"
        ((EXPIRESDOS++))
    else
        DIAS="$REST"
        STATUS="${GREEN}Active${RESET}"
        ((ACTIVES++))
    fi
fi

((TOTAL++))

printf "${CYAN}║${WHITE} %02d ${CYAN}║ ${WHITE}%-16s ${CYAN}║ ${WHITE}%-12s ${CYAN}║ ${WHITE}%-6s ${CYAN}║ %-33b${CYAN}║${RESET}\n" \
"$TOTAL" "$USER" "$FECHA" "$DIAS" "$STATUS"

done

echo -e "${CYAN}╠════╩══════════════════╩══════════════╩════════╩══════════════════════════╣${RESET}"
echo -e "${WHITE} Total Users : ${GREEN}$TOTAL"
echo -e "${WHITE} Actives        : ${GREEN}$ACTIVES"
echo -e "${WHITE} Expiresdos      : ${RED}$EXPIRESDOS"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════╝${RESET}"

echo
read -n1 -s -r -p "Press any key to return..."
