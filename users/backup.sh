#!/bin/bash
#==================================================
# ORX Tunnel Multi Script
# User Backup SSH
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

BACKUP_DIR="/root/orx-tunnel-backups"

mkdir -p "$BACKUP_DIR"

while true; do

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}             💾 USER BACKUP USERS SSH 💾               ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

echo -e "${GREEN}[1]${WHITE} Crear Backup"
echo -e "${BLUE}[2]${WHITE} Restore Backup"
echo -e "${YELLOW}[3]${WHITE} View Backups"
echo -e "${RED}[4]${WHITE} Delete Backup"
echo -e "${CYAN}[0]${WHITE} Return"

echo
read -rp "$(echo -e "${GREEN}Select an option:${RESET} ")" OP

case "$OP" in

1)

FECHA=$(date +%d-%m-%Y_%H-%M-%S)
FILE="$BACKUP_DIR/backup_$FECHA.tar.gz"

tar -czf "$FILE" \
/etc/passwd \
/etc/shadow \
/etc/group \
/etc/gshadow 2>/dev/null

echo
echo -e "${GREEN}✔ Backup created successfully.${RESET}"
echo -e "${WHITE}File:${GREEN} $FILE${RESET}"

sleep 3
;;

2)

clear

echo -e "${CYAN}══════════════ BACKUPS DISPONIBLES ══════════════${RESET}"
echo

mapfile -t LIST < <(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null)

if [ ${#LIST[@]} -eq 0 ]; then
    echo -e "${RED}None exist backups.${RESET}"
    sleep 2
    continue
fi

i=1
for FILE in "${LIST[@]}"; do
    echo "[$i] $(basename "$FILE")"
    ((i++))
done

echo
read -rp "Select: " NUM

FILE="${LIST[$((NUM-1))]}"

[[ -z "$FILE" ]] && {
echo -e "${RED}Selection invalid.${RESET}"
sleep 2
continue
}

read -rp "Restore this backup? [Y/N]: " RESP

case "$RESP" in
s|S|y|Y|yes|Yes)

tar -xzf "$FILE" -C /

echo
echo -e "${GREEN}✔ Backup restaurado successfully.${RESET}"
sleep 3
;;

*)
echo
echo -e "${YELLOW}Operation cancelled.${RESET}"
sleep 2
;;
esac
;;

3)

clear

echo -e "${CYAN}══════════════ LIST OF BACKUPS ══════════════${RESET}"
echo

if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then

for FILE in "$BACKUP_DIR"/*.tar.gz
do

SIZE=$(du -h "$FILE" | awk '{print $1}')
DATE=$(date -r "$FILE" +"%d/%m/%Y %H:%M")

echo -e "${GREEN}$(basename "$FILE")${RESET}"
echo -e " ${WHITE}Size:${GREEN} $SIZE"
echo -e " ${WHITE}Fecha :${GREEN} $DATE"
echo

done

else

echo -e "${RED}None exist backups.${RESET}"

fi

read -n1 -s -r -p "Press any key..."
;;

4)

clear

mapfile -t LIST < <(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null)

if [ ${#LIST[@]} -eq 0 ]; then
    echo -e "${RED}None exist backups.${RESET}"
    sleep 2
    continue
fi

echo -e "${CYAN}══════════════ DELETE BACKUP ══════════════${RESET}"
echo

i=1
for FILE in "${LIST[@]}"
do
echo "[$i] $(basename "$FILE")"
((i++))
done

echo
read -rp "Select: " NUM

FILE="${LIST[$((NUM-1))]}"

[[ -z "$FILE" ]] && {
echo -e "${RED}Selection invalid.${RESET}"
sleep 2
continue
}

rm -f "$FILE"

echo
echo -e "${GREEN}✔ Backup deleted.${RESET}"
sleep 2
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
