#!/bin/bash

BASE="/etc/orx-tunnel"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
MAGENTA="\e[1;95m"
RESET="\e[0m"

while true; do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}              🚀 SPEEDTEST${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo
echo " [1] ➮ Run Speedtest"
echo
echo " [0] ➮ Return"
echo

read -rp " ► Option: " OP

case "$OP" in

1)
    if command -v speedtest >/dev/null 2>&1; then
        speedtest
    else
        echo
        echo -e "${RED}❌ Official speedtest is not installed.${RESET}"
        echo
        echo "Install it first and try again."
    fi

    echo
    read -n1 -r -p "Press any key to continue..."
;;

0)
    exec bash "$BASE/tools/menu.sh"
;;

*)
    echo "❌ Invalid option."
    sleep 2
;;

esac

done
