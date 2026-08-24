#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Block / Unblock Users SSH
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

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}         🔒 BLOQUEAR / DESBLOQUEAR USERS SSH 🔓        ${CYAN}║${RESET}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"

echo -e "${GREEN}[1]${WHITE} Block user"
echo -e "${BLUE}[2]${WHITE} Unblock user"
echo -e "${YELLOW}[3]${WHITE} View status of users"
echo -e "${RED}[0]${WHITE} Return"

echo
read -rp "$(echo -e "${GREEN}Select an option:${RESET} ")" OP

case "$OP" in

1)

clear
echo -e "${CYAN}══════════════ USERS DISPONIBLES ══════════════${RESET}"
echo

awk -F: '$3>=1000 && $1!="nobody"{print NR") "$1}' /etc/passwd

echo
read -rp "User a block: " USER

if id "$USER" &>/dev/null; then
    passwd -l "$USER" >/dev/null 2>&1
    pkill -u "$USER" >/dev/null 2>&1

    echo
    echo -e "${GREEN}✔ User ${WHITE}$USER${GREEN} bloqueado successfully.${RESET}"
else
    echo
    echo -e "${RED}El user does not exist.${RESET}"
fi

sleep 2
;;

2)

clear
echo -e "${CYAN}══════════════ USERS BLOQUEADOS ══════════════${RESET}"
echo

for U in $(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd)
do
    if passwd -S "$U" 2>/dev/null | awk '{print $2}' | grep -q "L"; then
        echo "• $U"
    fi
done

echo
read -rp "User a unblock: " USER

if id "$USER" &>/dev/null; then
    passwd -u "$USER" >/dev/null 2>&1

    echo
    echo -e "${GREEN}✔ User ${WHITE}$USER${GREEN} desbloqueado successfully.${RESET}"
else
    echo
    echo -e "${RED}El user does not exist.${RESET}"
fi

sleep 2
;;

3)

clear

echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}          STATUS DE LOS USERS             ${CYAN}║${RESET}"
echo -e "${CYAN}╠════╦════════════════════╦═══════════════════╣${RESET}"

printf "${CYAN}║${WHITE} %-2s ${CYAN}║ ${WHITE}%-18s ${CYAN}║ ${WHITE}%-17s${CYAN}║${RESET}\n" \
"N°" "USER" "STATUS"

echo -e "${CYAN}╠════╬════════════════════╬═══════════════════╣${RESET}"

i=1

for USER in $(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd)
do

if passwd -S "$USER" 2>/dev/null | awk '{print $2}' | grep -q "L"; then
    STATUS="${RED}Bloqueado"
else
    STATUS="${GREEN}Active"
fi

printf "${CYAN}║${WHITE} %02d ${CYAN}║ ${WHITE}%-18s ${CYAN}║ %-26b${CYAN}║${RESET}\n" \
"$i" "$USER" "$STATUS"

((i++))

done

echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"

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
