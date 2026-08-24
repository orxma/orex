#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Edit / Renew User SSH
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

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${YELLOW}           ♻ EDIT / RENEW SSH USER          ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"

USERS=$(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd)

if [[ -z "$USERS" ]]; then
    echo -e "${RED}None exist users SSH.${RESET}"
    sleep 2
    exit
fi

i=1
declare -a LIST

while read -r USER; do
    FECHA=$(chage -l "$USER" | grep "Account expires" | cut -d: -f2)
    printf "${GREEN}[%02d]${WHITE} %-18s ${GRAY}%s${RESET}\n" "$i" "$USER" "$FECHA"
    LIST[$i]="$USER"
    ((i++))
done <<< "$USERS"

echo
read -rp "$(echo -e "${GREEN}Select a user [0=Exit]: ${RESET}")" NUM

[[ "$NUM" == "0" ]] && exit

USER="${LIST[$NUM]}"

if [[ -z "$USER" ]]; then
    echo
    echo -e "${RED}User invalid.${RESET}"
    sleep 2
    continue
fi

while true; do

clear

FECHA=$(chage -l "$USER" | grep "Account expires" | cut -d: -f2)

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}             👤 User: ${WHITE}$USER${CYAN}                  ║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${WHITE} Expires: ${GREEN}$FECHA${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"

echo -e "${GREEN}[1]${WHITE} Change password"
echo -e "${YELLOW}[2]${WHITE} Renew account"
echo -e "${BLUE}[3]${WHITE} Change password and renew"
echo -e "${RED}[0]${WHITE} Return"

echo
read -rp "$(echo -e "${GREEN}Option: ${RESET}")" OP

case "$OP" in

1)

read -rsp "$(echo -e "${GREEN}New password: ${RESET}")" PASS
echo

[[ -z "$PASS" ]] && {
echo -e "${RED}Password empty.${RESET}"
sleep 2
continue
}

echo "$USER:$PASS" | chpasswd

echo
echo -e "${GREEN}✔ Password updated.${RESET}"
sleep 2
;;

2)

read -rp "$(echo -e "${GREEN}Days to renew: ${RESET}")" DIAS

[[ -z "$DIAS" ]] && DIAS=30

FECHA=$(date -d "+$DIAS days" +"%Y-%m-%d")

chage -E "$FECHA" "$USER"

echo
echo -e "${GREEN}✔ Account renovada until:${WHITE} $FECHA${RESET}"
sleep 2
;;

3)

read -rsp "$(echo -e "${GREEN}New password: ${RESET}")" PASS
echo

read -rp "$(echo -e "${GREEN}Days to renew: ${RESET}")" DIAS

[[ -z "$DIAS" ]] && DIAS=30

FECHA=$(date -d "+$DIAS days" +"%Y-%m-%d")

echo "$USER:$PASS" | chpasswd
chage -E "$FECHA" "$USER"

echo
echo -e "${GREEN}✔ User updated successfully.${RESET}"
echo -e "${WHITE} User : ${GREEN}$USER"
echo -e "${WHITE} Expires  : ${GREEN}$FECHA"
sleep 3
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

break

done
