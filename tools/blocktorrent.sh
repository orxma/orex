#!/bin/bash

#==================================================
# ORX Tunnel Multi Script
# Block Torrent
#==================================================

BASE="/etc/orx-tunnel"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

bloquear() {

echo "⏳ Blocking BitTorrent..."

iptables -I INPUT -p tcp --dport 6881:6999 -j DROP
iptables -I OUTPUT -p tcp --sport 6881:6999 -j DROP

iptables -I INPUT -p udp --dport 6881:6999 -j DROP
iptables -I OUTPUT -p udp --sport 6881:6999 -j DROP

iptables -I INPUT -m string --algo bm --string "BitTorrent" -j DROP
iptables -I INPUT -m string --algo bm --string "peer_id=" -j DROP
iptables -I INPUT -m string --algo bm --string ".torrent" -j DROP
iptables -I INPUT -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -I INPUT -m string --algo bm --string "info_hash" -j DROP

echo ""
echo -e "${GREEN}✅ BitTorrent blocked successfully.${RESET}"

sleep 3

}

desbloquear() {

echo "⏳ Removing rules..."

iptables -F

echo ""
echo -e "${GREEN}✅ Rules removed.${RESET}"

sleep 3

}

while true
do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}          🛡️ Block Torrent 🛡️${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo ""
echo " [1] ➮ Block BitTorrent"
echo " [2] ➮ Unblock"
echo ""
echo " [0] ➮ Return"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

read -rp " ► Option: " op

case "$op" in

1)
bloquear
;;

2)
desbloquear
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
