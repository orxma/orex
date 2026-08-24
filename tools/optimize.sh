#!/bin/bash

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

source "$CONFIG"

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "         OPTIMIZE VPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Current status: $OPTIMIZAR"
echo ""

if [[ "$OPTIMIZAR" == "OFF" ]]; then
    echo "[1] Enable optimization"
else
    echo "[1] Disable optimization"
fi

echo "[0] Return"
echo ""

read -rp "► Option: " OP

case "$OP" in

1)

if [[ "$OPTIMIZAR" == "OFF" ]]; then

echo ""
echo "Applying optimization..."

cat >/etc/sysctl.d/99-orx-tunnel.conf <<EOF
net.core.somaxconn=4096
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65000
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.file-max=2097152
EOF

sysctl --system >/dev/null 2>&1

ulimit -n 1048576

sed -i 's/OPTIMIZAR=OFF/OPTIMIZAR=ON/' "$CONFIG"

echo ""
echo "✅ Optimization enabled successfully."

else

echo ""
echo "Restoring configuration..."

rm -f /etc/sysctl.d/99-orx-tunnel.conf

sysctl --system >/dev/null 2>&1

sed -i 's/OPTIMIZAR=ON/OPTIMIZAR=OFF/' "$CONFIG"

echo ""
echo "✅ Optimization disabled."

fi

sleep 2

exec bash "$BASE/menu.sh"

;;

0)

exec bash "$BASE/menu.sh"

;;

*)

echo "Invalid option."

sleep 1

exec bash "$BASE/menu.sh"

;;

esac
