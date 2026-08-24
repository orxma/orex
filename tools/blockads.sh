#!/bin/bash

#==================================================
# ORX Tunnel Multi Script
# Block Ads
#==================================================

BASE="/etc/orx-tunnel"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

HOSTS="/etc/hosts"

bloquear() {

echo ""
echo "⏳ Blocking ads..."

cp "$HOSTS" "$HOSTS.bak"

cat <<EOF >> "$HOSTS"

# ORX Tunnel Block Ads
0.0.0.0 ads.google.com
0.0.0.0 adservice.google.com
0.0.0.0 pagead2.googlesyndication.com
0.0.0.0 googleads.g.doubleclick.net
0.0.0.0 doubleclick.net
0.0.0.0 ad.doubleclick.net
0.0.0.0 ads.yahoo.com
0.0.0.0 ads.facebook.com
0.0.0.0 graph.facebook.com
0.0.0.0 ads.twitter.com
0.0.0.0 app-measurement.com
0.0.0.0 analytics.google.com
0.0.0.0 ssl.google-analytics.com
0.0.0.0 www.google-analytics.com
EOF

echo ""
echo -e "${GREEN}✅ Ads blocked.${RESET}"

sleep 3

}

desbloquear() {

echo ""
echo "⏳ Restoring hosts file..."

if [[ -f "$HOSTS.bak" ]]; then
    mv -f "$HOSTS.bak" "$HOSTS"
    echo ""
    echo -e "${GREEN}✅ Block removed.${RESET}"
else
    echo ""
    echo -e "${RED}❌ No backup copy exists.${RESET}"
fi

sleep 3

}

while true
do

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}             🚫 BLOCK ADS${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo ""
echo " [1] ➮ Block Ads"
echo " [2] ➮ Unblock Ads"
echo ""
echo " [0] ➮ Return"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

read -rp " ► Option: " OP

case "$OP" in

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
