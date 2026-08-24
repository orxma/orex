#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# Delete Users SSH
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
echo -e "${CYAN}║${RED}             🗑 DELETE USERS SSH              ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"

USERS=$(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd)

if [[ -z "$USERS" ]]; then
    echo -e "${YELLOW}None exist users SSH to delete.${RESET}"
    echo
    read -n1 -s -r -p "Press any key to exit..."
    exit
fi

echo -e "${WHITE}Users availables:${RESET}"
echo

i=1
declare -a LIST

while read -r user; do
    FECHA=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
    printf "${GREEN}[%02d]${WHITE} %-18s ${GRAY}%s${RESET}\n" "$i" "$user" "$FECHA"
    LIST[$i]="$user"
    ((i++))
done <<< "$USERS"

echo
echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "${YELLOW}Examples:${RESET}"
echo -e " ${WHITE}1${RESET}        -> Delete a user"
echo -e " ${WHITE}1 3 5${RESET}    -> Delete varios users"
echo -e " ${WHITE}0${RESET}        -> Cancelar"
echo
read -rp "$(echo -e "${GREEN}Select:${RESET} ")" OP

[[ "$OP" == "0" ]] && exit

echo
echo -e "${RED}The following users will be deleted:${RESET}"

VALIDO=0

for N in $OP; do
    if [[ -n "${LIST[$N]}" ]]; then
        echo -e " ${WHITE}• ${LIST[$N]}"
        VALIDO=1
    fi
done

[[ $VALIDO -eq 0 ]] && {
    echo
    echo -e "${RED}Selection invalid.${RESET}"
    sleep 2
    continue
}

echo
read -rp "$(echo -e "${YELLOW}Confirm? [Y/N]: ${RESET}")" RESP

case "$RESP" in
s|S|y|Y|Yes|yes)

BORRADOS=0

for N in $OP; do
    USER="${LIST[$N]}"

    if [[ -n "$USER" ]]; then
        pkill -u "$USER" &>/dev/null
        userdel -f "$USER" &>/dev/null
        ((BORRADOS++))
    fi
done

echo
echo -e "${GREEN}✔ $BORRADOS user(s) deleted(s).${RESET}"
sleep 2
;;

*)
echo
echo -e "${YELLOW}Operation cancelled.${RESET}"
sleep 2
;;
esac

break

done
