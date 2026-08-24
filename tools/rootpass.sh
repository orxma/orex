#!/bin/bash

BASE="/etc/orx-tunnel"

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "      CHANGE ROOT PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify root
if [[ $EUID -ne 0 ]]; then
    echo "❌ You must run the script as root user."
    echo ""
    echo "Run:"
    echo "sudo -i"
    echo ""
    read -n1 -r -p "Press any key to return..."
    exec bash "$BASE/protocols/menu.sh"
fi

read -rsp "🔑 New password: " PASS1
echo
read -rsp "🔑 Confirm password: " PASS2
echo

if [[ "$PASS1" != "$PASS2" ]]; then
    echo ""
    echo "❌ Passwords do not match."
    sleep 2
    exec bash "$BASE/protocols/menu.sh"
fi

echo "root:$PASS1" | chpasswd || {
    echo ""
    echo "❌ Could not change the password."
    sleep 2
    exec bash "$BASE/protocols/menu.sh"
}

# Enable root SSH access
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep -q "^PermitRootLogin" /etc/ssh/sshd_config || \
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Enable password authentication
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || \
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Ubuntu 22.04 and 24.04
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/99-root.conf <<EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF

systemctl restart ssh 2>/dev/null || systemctl restart sshd

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ PASSWORD CHANGED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "User        : root"
echo "Password    : $PASS1"
echo "SSH Root    : Enabled"
echo ""
read -n1 -r -p "Press any key to return..."

exec bash "$BASE/protocols/menu.sh"
