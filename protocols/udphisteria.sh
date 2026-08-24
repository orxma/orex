#!/bin/bash

# =========================================================
# GESTOR HYSTERIA V1 - PRO UNIFICADO
# =========================================================

# --- Matriz of Colores ---
COLOR[0]='\033[1;37m' # Blanco
COLOR[1]='\e[93m'     # Amarillo claro
COLOR[2]='\e[32m'     # Verde
COLOR[3]='\e[31m'     # Rojo
COLOR[4]='\e[34m'     # Azul
COLOR[5]='\e[95m'     # Magenta
COLOR[6]='\033[1;97m' # Blanco brillante
COLOR[7]='\033[36m'   # Cian
NC='\e[0m'

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="/etc/hysteria/config.json"
EXECUTABLE="/usr/local/bin/hysteria1"
SYSTEMD_SERVICE="/etc/systemd/system/hysteria1-server.service"

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

mkdir -p "$BASE"
touch "$CONFIG"

config_set() {
    KEY="$1"
    VALUE="$2"

    if grep -q "^${KEY}=" "$CONFIG"; then
        sed -i "s|^${KEY}=.*|${KEY}=${VALUE}|" "$CONFIG"
    else
        echo "${KEY}=${VALUE}" >> "$CONFIG"
    fi
}

config_get() {
    grep "^$1=" "$CONFIG" | cut -d= -f2-
}

# --- Crear comando permanente 'menuhy' ---
# Use a more robust method so the command always works
if [[ ! -f "/usr/local/bin/menuhy" ]]; then
    echo "bash $(readlink -f "$0")" > /usr/local/bin/menuhy
    chmod +x /usr/local/bin/menuhy
fi

stop_hys() { systemctl stop hysteria1-server > /dev/null 2>&1; pkill -f hysteria1 > /dev/null 2>&1; }

# --- Function of Logs mejorada ---
show_logs() {
    echo -e "${COLOR[1]}Showing logs (Press Ctrl+C to stop reading)...${NC}"
    echo -e "${COLOR[7]}Una vez que te detengas, press Enter to return to the menu.${NC}"
    sleep 2
    journalctl -u hysteria1-server -n 50 -f
    echo -e "\n${COLOR[2]}Lectura of log completed.${NC}"
    read -p "Press [Enter] to return to the menu..."
}

# --- Function to show configuration ---
show_config() {
    clear

    if systemctl is-active --quiet hysteria1-server; then
        STATUS="${COLOR[2]}● ACTIVE${NC}"
    else
        STATUS="${COLOR[3]}● STOPPED${NC}"
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${COLOR[3]}Does not exist none configuration installed.${NC}"
        read -p "Press Enter..."
        return
    fi

    IP=$(curl -s ipv4.icanhazip.com)
    PORT=$(grep -oP '"listen":\s*":\K[0-9]+' "$CONFIG_FILE")
    AUTH="User SSH + Password SSH"
    OBFS=$(grep -oP '"obfs":\s*"\K[^"]+' "$CONFIG_FILE")

    echo -e "${COLOR[5]}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${COLOR[5]}║${NC}${COLOR[6]}           SERVER INFORMATION UDP          ${NC}${COLOR[5]}║${NC}"
    echo -e "${COLOR[5]}╠══════════════════════════════════════════════════════╣${NC}"
    printf "${COLOR[5]}║${NC} %-18s %b\n" "Status :" "$STATUS"
    printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}%s${NC}\n" "IP Public :" "$IP"
    printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}%s${NC}\n" "Port UDP :" "$PORT"
    printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}%s${NC}\n" "AUTH :" "$AUTH"

    if [[ -n "$OBFS" ]]; then
        printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}%s${NC}\n" "OBFS :" "$OBFS"
    else
        printf "${COLOR[5]}║${NC} %-18s ${COLOR[3]}Not configured${NC}\n" "OBFS :"
    fi

    DOMAIN=$(config_get SERVER_DOMAIN)
if [[ -z "$DOMAIN" ]]; then
    echo
    echo -e "${COLOR[3]}No domain is configured.${NC}"
    echo -e "${COLOR[1]}Configura first the domain dthe server.${NC}"
    echo
    read -p "Press Enter to continue..."
    return
fi

printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}%s${NC}\n" "SNI :" "$DOMAIN"
    printf "${COLOR[5]}║${NC} %-18s ${COLOR[7]}h3${NC}\n" "ALPN :"

    echo -e "${COLOR[5]}╚══════════════════════════════════════════════════════╝${NC}"
    echo
    read -p "Press Enter to return..."
}

# --- Function of Modification ---
modify_config() {
while true; do
    clear

    PORT=$(grep -oP '"listen":\s*":\K[0-9]+' "$CONFIG_FILE")
    AUTH="EXTERNAL"
    OBFS=$(grep -oP '"obfs":\s*"\K[^"]+' "$CONFIG_FILE")

    echo -e "${COLOR[5]}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${COLOR[5]}║${NC}${COLOR[6]}           CONFIGURATION PANEL UDP          ${NC}${COLOR[5]}║${NC}"
    echo -e "${COLOR[5]}╠════════════════════════════════════════════════════╣${NC}"
    echo -e "${COLOR[5]}║${NC} Port : ${COLOR[7]}${PORT}${NC}"
    echo -e "${COLOR[5]}║${NC} AUTH   : ${COLOR[7]}${AUTH}${NC}"
    echo -e "${COLOR[5]}║${NC} OBFS   : ${COLOR[7]}${OBFS:-Not configured}${NC}"
    echo -e "${COLOR[5]}╠════════════════════════════════════════════════════╣${NC}"
    echo -e " ${COLOR[2]}1${NC}) Change Port UDP"
echo -e " ${COLOR[2]}2${NC}) Change OBFS"
echo -e " ${COLOR[2]}3${NC}) Delete OBFS"
echo -e " ${COLOR[2]}0${NC}) Return"
    echo -e "${COLOR[5]}╚════════════════════════════════════════════════════╝${NC}"
    echo

    read -p "Select: " opt

    case $opt in
1)
    read -p "New Port: " NEW
    sed -i "s/\"listen\": \":.*/\"listen\": \":$NEW\",/g" "$CONFIG_FILE"
    ;;

2)
    read -p "New OBFS: " NEW
    if grep -q '"obfs"' "$CONFIG_FILE"; then
        sed -i "s/\"obfs\": \".*\"/\"obfs\": \"$NEW\"/g" "$CONFIG_FILE"
    else
        sed -i "3i\\    \"obfs\": \"$NEW\"," "$CONFIG_FILE"
    fi
    ;;

3)
    sed -i '/"obfs"/d' "$CONFIG_FILE"
    ;;

0)
    return
    ;;

*)
    echo -e "${COLOR[3]}Option invalid.${NC}"
    sleep 1
    ;;
esac

    systemctl restart hysteria1-server
config_set "HYSTERIA_PORT" "$(grep -oP '"listen":\s*":\K[0-9]+' "$CONFIG_FILE")"
config_set "HYSTERIA_AUTH" "EXTERNAL"

OBFS=$(grep -oP '"obfs":\s*"\K[^"]+' "$CONFIG_FILE")
config_set "HYSTERIA_OBFS" "${OBFS:-OFF}"
    echo
    echo -e "${COLOR[2]}✔ Configuration updated successfully.${NC}"
    sleep 2

done
}

# --- Proceso of Installation ---
install_hys() {

clear
DOMAIN=$(config_get SERVER_DOMAIN)

if [[ -z "$DOMAIN" ]]; then
    echo
    echo -e "${COLOR[3]}No domain is configured.${NC}"
    echo -e "${COLOR[1]}Configura first the domain dthe server.${NC}"
    echo
    read -p "Press Enter to continue..."
    return
fi

echo -e "${COLOR[5]}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${COLOR[5]}║${NC}${COLOR[6]}         HYSTERIA V1 PRO INSTALLER          ${NC}${COLOR[5]}║${NC}"
echo -e "${COLOR[5]}╚════════════════════════════════════════════════════╝${NC}"
echo

port=$(shuf -i 2000-65000 -n1)

read -p "OBFS [Optional]: " obfs_key

mkdir -p "$CONFIG_DIR"

progress() {
    echo -ne "\r${COLOR[2]}[$1]${NC} $2..."
}

progress "1/6" "Downloading Core"

ARCH=$(uname -m)

case "$ARCH" in
x86_64) FILE="hysteria-linux-amd64" ;;
aarch64|arm64) FILE="hysteria-linux-arm64" ;;
armv7l) FILE="hysteria-linux-arm" ;;
*) echo; echo "Unsupported architecture."; read; return ;;
esac

wget -qO "$EXECUTABLE" "https://github.com/apernet/hysteria/releases/download/v1.3.5/$FILE" || {
echo
echo "Failed to download."
read
return
}

chmod +x "$EXECUTABLE"

progress "2/6" "Generando Certificados"

openssl ecparam -genkey -name prime256v1 -out "$CONFIG_DIR/private.key" >/dev/null 2>&1

openssl req -new -x509 \
-days 36500 \
-nodes \
-key "$CONFIG_DIR/private.key" \
-out "$CONFIG_DIR/cert.crt" \
-subj "/CN=$DOMAIN" >/dev/null 2>&1

cat > /usr/local/bin/hysteria-auth.sh <<'EOF'
#!/bin/bash

AUTH="$2"
USER="${AUTH%%:*}"
PASS="${AUTH#*:}"

id "$USER" &>/dev/null || exit 1

python3 - "$USER" "$PASS" <<'PY'
import sys, pam
u = sys.argv[1]
p = sys.argv[2]
sys.exit(0 if pam.pam().authenticate(u, p) else 1)
PY
EOF

chmod +x /usr/local/bin/hysteria-auth.sh

progress "3/6" "Creating Configuration"

[[ -n "$obfs_key" ]] && OBFS="\"obfs\":\"$obfs_key\","

cat > "$CONFIG_FILE" <<EOF
{
  "protocol":"udp",
  "listen":":$port",
  $OBFS
  "cert":"$CONFIG_DIR/cert.crt",
  "key":"$CONFIG_DIR/private.key",
  "alpn":"h3",
  "auth":{
    "mode":"external",
    "config":{
      "cmd":"/usr/local/bin/hysteria-auth.sh"
    }
  }
}
EOF

progress "4/6" "Creating Service"

cat > "$SYSTEMD_SERVICE" <<EOF
[Unit]
Description=Hysteria V1
After=network.target

[Service]
ExecStart=$EXECUTABLE -config $CONFIG_FILE server
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

progress "5/6" "Starting Service"

systemctl daemon-reload
systemctl enable hysteria1-server >/dev/null 2>&1
systemctl restart hysteria1-server

progress "6/6" "Finalizando"

sleep 1

clear

IP=$(curl -s ipv4.icanhazip.com)

echo -e "${COLOR[2]}"
echo "══════════════════════════════════════"
echo "      INSTALLATION COMPLETED"
echo "══════════════════════════════════════"
echo -e "${NC}"

echo "IP      : $IP"
echo "Port  : $port"
echo "AUTH    : User SSH + Password SSH"
echo "Example : kevin:1234"
echo "OBFS    : ${obfs_key:-Not configured}"
echo "SNI     : $DOMAIN"
echo "ALPN    : h3"

config_set "HYSTERIA" "ON"
config_set "HYSTERIA_PORT" "$port"
config_set "HYSTERIA_AUTH" "EXTERNAL"
config_set "HYSTERIA_OBFS" "${obfs_key:-OFF}"

echo
read -p "Press Enter to continue..."

}
# ==========================
# AUTOMATIC MODE
# ==========================

if [[ "$1" == "--auto" ]]; then
    echo "🚀 Installing Hysteria V1 automatically..."

    install_hys

    if systemctl is-active --quiet hysteria1-server; then
        echo "✅ Hysteria V1 installed successfully."
        exit 0
    else
        echo "❌ Error installing Hysteria V1."
        exit 1
    fi
fi
# ==========================
# MAIN MENU PRO
# ==========================
while true; do
    clear

    if systemctl is-active --quiet hysteria1-server; then
        STATUS="${COLOR[2]}● ACTIVE${NC}"
    else
        STATUS="${COLOR[3]}● STOPPED${NC}"
    fi

    PORT=$(grep -oP '"listen":\s*":\K[0-9]+' "$CONFIG_FILE" 2>/dev/null)
AUTH="EXTERNAL"
    echo -e "${COLOR[5]}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${COLOR[5]}║${NC}${COLOR[6]}              HYSTERIA V1 - UDP MANAGER PRO             ${NC}${COLOR[5]}║${NC}"
    echo -e "${COLOR[5]}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${COLOR[5]}║${NC} Status : $STATUS"
    echo -e "${COLOR[5]}║${NC} Port : ${COLOR[7]}${PORT:-Not installed}${NC}"
    echo -e "${COLOR[5]}║${NC} Auth   : ${COLOR[7]}${AUTH:-No available}${NC}"
    echo -e "${COLOR[5]}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e " ${COLOR[2]}[1]${NC} 🚀 Install Hysteria V1"
    echo -e " ${COLOR[2]}[2]${NC} 🗑️  Uninstall Hysteria"
    echo -e " ${COLOR[2]}[3]${NC} 🔄 Gestionar Service"
    echo -e " ${COLOR[2]}[4]${NC} ⚙️  Modificar Configuration"
    echo -e " ${COLOR[2]}[5]${NC} 📄 View Configuration"
    echo -e " ${COLOR[2]}[6]${NC} 📜 View Logs"
    echo -e " ${COLOR[2]}[0]${NC} 🚪 Exit"
    echo
    echo -ne "${COLOR[7]}Select an option ➜ ${NC}"
    read menuInput

    case $menuInput in
        1) install_hys ;;
        2)
          stop_hys

systemctl disable hysteria1-server >/dev/null 2>&1

rm -rf "$CONFIG_DIR"
rm -f "$EXECUTABLE"
rm -f "$SYSTEMD_SERVICE"

systemctl daemon-reload

config_set "HYSTERIA" "OFF"
config_set "HYSTERIA_PORT" ""
config_set "HYSTERIA_AUTH" ""
config_set "HYSTERIA_OBFS" ""
            echo -e "${COLOR[2]}✔ Hysteria deleted successfully.${NC}"
            sleep 2
        ;;
        3)
            clear
            echo -e "${COLOR[6]}=========== GESTOR DEL SERVICE ===========${NC}"
            echo
            echo " 1) Iniciar"
            echo " 2) Stop"
            echo " 3) Restart"
            echo " 4) Status"
            echo " 0) Return"
            echo
            read -p "Select: " srv

            case $srv in
                1) systemctl start hysteria1-server ;;
                2) systemctl stop hysteria1-server ;;
                3) systemctl restart hysteria1-server ;;
                4)
                    systemctl status hysteria1-server --no-pager
                    read -p "Enter to continue..."
                ;;
            esac
        ;;
        4) modify_config ;;
        5) show_config ;;
        6) show_logs ;;
        0) exec bash "$BASE/menu.sh" ;;
*)
echo "❌ Option invalid."
sleep 2
exec bash "$BASE/protocols/menu.sh"
;;
    esac
done
