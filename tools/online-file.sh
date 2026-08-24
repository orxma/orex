#!/bin/bash

#==================================================
# ORX Tunnel Multi Script
# Online File
#==================================================

BASE="/etc/orx-tunnel"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

while true
do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}          ☁️ Online File ☁️${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo ""
echo " [1] ➮ Upload File"
echo " [2] ➮ View Directory Files"
echo ""
echo " [0] ➮ Return"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

read -rp " ► Option: " OP

case "$OP" in

1)

echo ""
read -rp "Full path of the file: " FILE

if [[ ! -f "$FILE" ]]; then
    echo ""
    echo -e "${RED}❌ File not found.${RESET}"
    sleep 3
    continue
fi

echo ""
echo "⏳ Uploading file..."

URL=$(curl -s --upload-file "$FILE" https://transfer.sh/$(basename "$FILE"))

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${WHITE}✅ File uploaded successfully${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "📎 Link:"
echo ""
echo "$URL"
echo ""

read -n1 -r -p "Press any key to continue..."

;;

2)

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}          📂 Available Files${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

ls -lh

echo ""
read -n1 -r -p "Press any key to continue..."

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
