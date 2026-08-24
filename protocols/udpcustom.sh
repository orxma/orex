#!/bin/bash

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

[[ ! -f "$CONFIG" ]] && {
    echo "❌ Does not exist configuration ORX Tunnel"
    exit 1
}

source "$CONFIG"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
WHITE="\e[1;97m"
RESET="\e[0m"


SERVICE="udp-custom"
PORT="2100"
BIN="/usr/bin/udp"
CONFIG_UDP="/usr/bin/config.json"


set_udp_status(){

if systemctl is-active --quiet "$SERVICE"; then
    STATUS="${GREEN}🟢 ACTIVE${RESET}"
else
    STATUS="${RED}🔴 STOPPED${RESET}"
fi

}


install_udp(){

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "       🚀 INSTALANDO UDP CUSTOM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


apt update -y

apt install -y curl wget iptables libpam0g


echo "⚙️ Activando IP Forward..."

sysctl -w net.ipv4.ip_forward=1

grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || \
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf


ARCH=$(uname -m)


case "$ARCH" in

x86_64)
URL="https://github.com/Depwisescript/UDP/raw/main/udp-custom-linux-amd64"
;;

aarch64)
URL="https://github.com/Depwisescript/UDP/raw/main/udp-custom-linux-arm"
;;

*)
echo "❌ Unsupported architecture: $ARCH"
return
;;

esac


echo "⬇️ Downloading UDP..."

curl -L -s -f "$URL" -o "$BIN"


if [[ ! -f "$BIN" ]]; then

echo "❌ Error downloading UDP"

return

fi


chmod +x "$BIN"



echo "📝 Creating configuration..."

cat > "$CONFIG_UDP" <<EOF
{
    "listen": ":2100",
    "stream_buffer": 33554432,
    "receive_buffer": 83886080,
    "auth": {
        "mode": "passwords"
    }
}
EOF



echo "⚙️ Creating service..."


cat > /etc/systemd/system/$SERVICE.service <<EOF
[Unit]
Description=UDP Custom Server ORX Tunnel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/bin
ExecStart=/usr/bin/udp server -exclude 2200,7300,7200,7100,323,10008,10004 /usr/bin/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload

systemctl enable "$SERVICE"

systemctl restart "$SERVICE"



if systemctl is-active --quiet "$SERVICE"; then

echo "UDP_CUSTOM=ON" >> "$CONFIG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ UDP CUSTOM INSTALLED"
echo "Port: $PORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

else

echo "❌ UDP did not start"
journalctl -u "$SERVICE" --no-pager -n 20

fi


sleep 3

}
remove_udp(){

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "       🗑️ DELETE UDP CUSTOM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


read -rp "Delete UDP Custom? (s/n): " CONFIRM


if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then

echo "❌ Cancelado"
sleep 2
return

fi



echo "⏳ Deteniendo service..."


systemctl stop "$SERVICE" 2>/dev/null

systemctl disable "$SERVICE" 2>/dev/null



echo "🧹 Deletendo files..."


rm -f "/etc/systemd/system/$SERVICE.service"

rm -f "$BIN"

rm -f "$CONFIG_UDP"



systemctl daemon-reload



echo "🧹 Limpiando reglas temporales..."


DEV=$(ip -4 route show default | awk '{print $5}' | head -1)



if [[ -n "$DEV" ]]; then


iptables -t nat -S PREROUTING 2>/dev/null \
| grep "2100" \
| sed 's/-A/-D/' \
| while read RULE
do
iptables -t nat $RULE 2>/dev/null
done



iptables -S INPUT 2>/dev/null \
| grep "2100" \
| sed 's/-A/-D/' \
| while read RULE
do
iptables $RULE 2>/dev/null
done


fi



sed -i '/^UDPCUSTOM=/d' "$CONFIG"

echo "UDP_CUSTOM=OFF" >> "$CONFIG"


echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ UDP CUSTOM REMOVED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


sleep 3

}



restart_udp(){


clear


echo "🔄 Restarting UDP Custom..."


systemctl restart "$SERVICE"



sleep 2



if systemctl is-active --quiet "$SERVICE"; then

echo "✅ Service active"

else

echo "❌ No could start"

journalctl -u "$SERVICE" --no-pager -n 15

fi


sleep 3


}



status_udp(){


clear


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "       📊 STATUS UDP CUSTOM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


echo ""


systemctl status "$SERVICE" --no-pager



echo ""

echo "Port interno: $PORT"


echo ""

echo "Escuchando UDP:"


ss -ulnp | grep ":$PORT"



echo ""

read -n1 -r -p "Press any key to continue..."

}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#               AUTOMATIC MODE                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

if [[ "$1" == "--auto" ]]; then
    echo "🚀 Installing UDP Custom automatically..."

    install_udp

    if systemctl is-active --quiet "$SERVICE"; then
        echo "✅ UDP Custom installed successfully."
        exit 0
    else
        echo "❌ Error installing UDP Custom."
        exit 1
    fi
fi
while true
do

clear

source "$CONFIG"


set_udp_status



echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${WHITE}             🚀 UDP CUSTOM MANAGER${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"


echo -e " Status   : $STATUS"
echo -e " Port   : $PORT"
echo -e " Service : udp-custom"


echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"


if [[ "$UDP_CUSTOM" == "ON" ]]; then


cat <<EOF

 [1] ➮ Uninstall UDP Custom
 [2] ➮ Restart Service
 [3] ➮ View Status

 [0] ➮ Return

EOF


else


cat <<EOF

 [1] ➮ Install UDP Custom

 [0] ➮ Return

EOF


fi



echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"


read -rp " ► Option: " OP



case "$OP" in


1)


if [[ "$UDP_CUSTOM" == "ON" ]]; then

remove_udp

else

install_udp

fi

;;



2)


if [[ "$UDP_CUSTOM" == "ON" ]]; then

restart_udp

else

echo "❌ UDP Custom is not installed"

sleep 2

fi

;;



3)


if [[ "$UDP_CUSTOM" == "ON" ]]; then

status_udp

else

echo "❌ UDP Custom is not installed"

sleep 2

fi

;;



0)


if [[ -f "$BASE/protocols/menu.sh" ]]; then

exec bash "$BASE/protocols/menu.sh"

else

clear

echo "❌ Menu principal not found"

sleep 2

exit

fi

;;



*)

echo "❌ Option invalid"

sleep 2

;;


esac


done
