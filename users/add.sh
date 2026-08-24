#!/bin/bash
#=========================================================
# ORX Tunnel Multi Script Premium
# Module: Create SSH User
# Version: Premium
# Autor: ORX Tunnel
#=========================================================

#========================#
#         COLORES        #
#========================#
GREEN='\e[1;92m'
RED='\e[1;91m'
YELLOW='\e[1;93m'
BLUE='\e[1;94m'
CYAN='\e[1;96m'
MAGENTA='\e[1;95m'
WHITE='\e[1;97m'
GRAY='\e[1;90m'
RESET='\e[0m'

#========================#
#      CONFIGURATION     #
#========================#

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

mkdir -p "$BASE"

[[ -f "$CONFIG" ]] && source "$CONFIG"

#========================#
#       FUNCIONES        #
#========================#

line() {
    printf "%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$CYAN" "$RESET"
}

pause() {
    echo
    read -rp "$(echo -e "${YELLOW}Press ENTER to continue...${RESET}")"
}

msg_ok() {
    echo -e "${GREEN}✔ $1${RESET}"
}

msg_error() {
    echo -e "${RED}✘ $1${RESET}"
}

msg_info() {
    echo -e "${CYAN}➜ $1${RESET}"
}

msg_warn() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}
  #========================#
# SINCRONIZAR PASSWORD CON ZIVPN
#========================#

sync_zivpn_password() {

    local PASS="$1"
    local ZIVPN_CONFIG="/etc/zivpn/config.json"

    # If ZiVPN is not installed, do nothing
    [[ ! -f "$ZIVPN_CONFIG" ]] && return 0

    # jq required
    if ! command -v jq >/dev/null 2>&1; then
        msg_warn "ZiVPN is installed pero jq is not available."
        return 1
    fi

    # Verificar JSON
    if ! jq empty "$ZIVPN_CONFIG" >/dev/null 2>&1; then
        msg_error "The file of configuration of ZiVPN is not valid."
        return 1
    fi

    # Comprobar if the password already exists
    if jq -e --arg pass "$PASS" \
        '.auth.config[]? | select(. == $pass)' \
        "$ZIVPN_CONFIG" >/dev/null 2>&1; then

        msg_info "The password already exists en ZiVPN."
        return 0
    fi

    local TMP
    TMP=$(mktemp)

    # Add password
    if jq --arg pass "$PASS" \
        '.auth.config += [$pass]' \
        "$ZIVPN_CONFIG" > "$TMP"; then

        chmod 600 "$TMP"
        mv "$TMP" "$ZIVPN_CONFIG"

        # Restart ZiVPN to aplicar cambios
        systemctl restart zivpn >/dev/null 2>&1

        if systemctl is-active --quiet zivpn; then
            msg_ok "Password synchronized with ZiVPN."
        else
            msg_warn "Password added, pero ZiVPN is not active."
        fi

    else

        rm -f "$TMP"
        msg_error "Could not add the password a ZiVPN."
        return 1
    fi
}
titulo() {

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}               ⚜ ORX Tunnel Multi Script ⚜                ${CYAN}║${RESET}"
echo -e "${CYAN}║${WHITE}                 CREAR SSH USER PREMIUM               ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo

}

#========================#
#      VARIABLES         #
#========================#

SERVER_DOMAIN="${SERVER_DOMAIN:-}"
OPENSSH="${OPENSSH:-OFF}"
DROPBEAR="${DROPBEAR:-OFF}"
WEBSOCKET="${WEBSOCKET:-OFF}"
SSL="${SSL:-OFF}"
SLOWDNS="${SLOWDNS:-OFF}"

#========================#
#    GET PUBLIC IP  #
#========================#

obtener_ip() {

IP=$(curl -4 -s --max-time 5 ifconfig.me)

[[ -z "$IP" ]] && \
IP=$(hostname -I | awk '{print $1}')

[[ -z "$IP" ]] && \
IP="0.0.0.0"

}

#========================#
#   INICIO DEL PROGRAMA  #
#========================#

while true; do

titulo

obtener_ip

#========================#
#   DATOS DEL USER    #
#========================#

while true; do
    read -rp "$(echo -e "${GREEN}👤 User               : ${RESET}")" USER

    USER=$(echo "$USER" | tr '[:upper:]' '[:lower:]')

    if [[ -z "$USER" ]]; then
        msg_error "Must enter a name of user."
        continue
    fi

    if ! [[ "$USER" =~ ^[a-z][a-z0-9_-]{2,31}$ ]]; then
        msg_error "Solo letters, numbers, _ y -. Minimum 3 caracteres."
        continue
    fi

    if id "$USER" &>/dev/null; then
        msg_error "El user already exists."
        continue
    fi

    break
done

echo

while true; do
    read -rsp "$(echo -e "${GREEN}🔑 Password            : ${RESET}")" PASS
    echo

    if [[ -z "$PASS" ]]; then
        msg_error "Must enter a password."
        continue
    fi

    if [[ ${#PASS} -lt 4 ]]; then
        msg_warn "Se recomienda a password of at least 4 caracteres."
    fi

    break
done

echo

while true; do
    read -rp "$(echo -e "${GREEN}📅 Duration (days)       : ${RESET}")" DIAS

    [[ -z "$DIAS" ]] && DIAS=30

    if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
        msg_error "Must enter a number."
        continue
    fi

    if (( DIAS <= 0 )); then
        msg_error "La duration must be greater than 0."
        continue
    fi

    break
done

echo

while true; do
    read -rp "$(echo -e "${GREEN}👥 Limit (0=Unlimited) : ${RESET}")" LIMITE

    [[ -z "$LIMITE" ]] && LIMITE=0

    if ! [[ "$LIMITE" =~ ^[0-9]+$ ]]; then
        msg_error "El limit must be a number."
        continue
    fi

    break
done

if (( LIMITE == 0 )); then
    LIMITE_MOSTRAR="♾ Unlimited"
else
    LIMITE_MOSTRAR="$LIMITE User(s)"
fi

#========================#
#   EXPIRATION DATE  #
#========================#

FECHA=$(date -d "+${DIAS} days" +"%Y-%m-%d")
FECHA_MOSTRAR=$(date -d "$FECHA" +"%d/%m/%Y")

#========================#
#    CREAR SSH USER   #
#========================#
msg_info "Creating user SSH..."

useradd -e "$FECHA" -M -s /usr/sbin/nologin "$USER"

if [[ $? -ne 0 ]]; then
    msg_error "Could not create the user."
    sleep 2
    continue
fi

echo "${USER}:${PASS}" | chpasswd

if [[ $? -ne 0 ]]; then
    msg_error "Could not establecer the password."

    userdel -f "$USER" &>/dev/null

    sleep 2
    continue
fi
#========================#
# SINCRONIZAR CON ZIVPN
#========================#

sync_zivpn_password "$PASS"

#========================#
# SAVE USER LIMIT
#========================#
mkdir -p /etc/orx-tunnel/limits
echo "$LIMITE" > /etc/orx-tunnel/limits/$USER

#========================#
# INSTALL AUTOMATIC LIMITER
#========================#
if [[ ! -f /usr/local/bin/orx-tunnel-limit.sh ]]; then
cat > /usr/local/bin/orx-tunnel-limit.sh << 'EOF'
#!/bin/bash

LIMIT_DIR="/etc/orx-tunnel/limits"

mkdir -p "$LIMIT_DIR"

for FILE in "$LIMIT_DIR"/*; do
    [ -f "$FILE" ] || continue

    USER=$(basename "$FILE")
    LIMIT=$(cat "$FILE")

    # 0 = unlimited
    [ "$LIMIT" = "0" ] && continue

    # Count unique IPs connected by SSH, Dropbear y WebSocket
IPS=$(ps -u "$USER" -o pid= | while read PID; do
    ss -tnp 2>/dev/null | grep "pid=$PID,"
done | awk '{print $5}' | cut -d: -f1 | sort -u | wc -l)
    if [ "$IPS" -gt "$LIMIT" ]; then
        pkill -KILL -u "$USER" 2>/dev/null
    fi
done
EOF

chmod +x /usr/local/bin/orx-tunnel-limit.sh
echo "* * * * * root /usr/local/bin/orx-tunnel-limit.sh" > /etc/cron.d/orx-tunnel-limit

systemctl enable cron >/dev/null 2>&1
systemctl restart cron >/dev/null 2>&1

fi

msg_ok "User created successfully."

HOST="${SERVER_DOMAIN:-$IP}"

echo
#========================#
# DETECTAR SERVICES     #
#========================#

# OpenSSH
SSH_PORTS=$(ss -ltnp 2>/dev/null | awk '/sshd/ {split($4,a,":"); print a[length(a)]}' | sort -nu | paste -sd "," -)
[[ -z "$SSH_PORTS" ]] && SSH_PORTS="22"

# Dropbear
DROPBEAR_PORTS=$(ss -ltnp 2>/dev/null | awk '/dropbear/ {split($4,a,":"); print a[length(a)]}' | sort -nu | paste -sd "," -)

# HAProxy
HAPROXY_PORTS=$(ss -ltnp 2>/dev/null | awk '/haproxy/ {split($4,a,":"); print a[length(a)]}' | sort -nu | paste -sd "," -)

# BadVPN
BADVPN_PORTS=$(ss -ltnp 2>/dev/null | awk '/badvpn/ {split($4,a,":"); print a[length(a)]}' | sort -nu | paste -sd "," -)

#========================#
# WEBSOCKET              #
#========================#

WS_PORT="80"
WSS_PORT="443"
WS_CDN_PORT="8080"

if [[ -n "$HAPROXY_PORTS" ]]; then

    [[ "$HAPROXY_PORTS" == *"80"* ]] && WS_PORT="80"
    [[ "$HAPROXY_PORTS" == *"443"* ]] && WSS_PORT="443"
    [[ "$HAPROXY_PORTS" == *"8080"* ]] && WS_CDN_PORT="8080"

fi

#========================#
# DOMINIO               #
#========================#

HOST="${SERVER_DOMAIN:-$IP}"

#========================#
# SLOWDNS              #
#========================#

if [[ -f /etc/slowdns/domain.conf ]]; then
    SLOWDNS_NS=$(cat /etc/slowdns/domain.conf)
else
    SLOWDNS_NS="N/D"
fi

if [[ -f /etc/slowdns/server.pub ]]; then
    SLOWDNS_KEY=$(cat /etc/slowdns/server.pub)
else
    SLOWDNS_KEY="N/D"
fi
#========================#
# STATUS DE SERVICES    #
#========================#

OPENSSH_STATUS="OFF"
DROPBEAR_STATUS="OFF"
SSL_STATUS="OFF"
WEBSOCKET_STATUS="OFF"
SLOWDNS_STATUS="OFF"

[[ -n "$SSH_PORTS" ]] && OPENSSH_STATUS="ON"
[[ -n "$DROPBEAR_PORTS" ]] && DROPBEAR_STATUS="ON"
[[ -n "$HAPROXY_PORTS" ]] && SSL_STATUS="ON"

if [[ "$SSL_STATUS" == "ON" ]]; then
    WEBSOCKET_STATUS="ON"
fi

if systemctl is-active --quiet slowdns 2>/dev/null; then
    SLOWDNS_STATUS="ON"
fi

#========================#
# PAYLOADS              #
#========================#

PAYLOAD_WS="GET / HTTP/1.1[crlf]Host: ${HOST}[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"

PAYLOAD_WSS="GET wss://${HOST}/ HTTP/1.1[crlf]Host: ${HOST}[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"

PAYLOAD_HTTP="[method] [host_port] HTTP/1.1[crlf]Host: ${HOST}[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"

#========================#
# CONNECTIONS LISTS      #
#========================#

WS_HTTP="${HOST}:${WS_PORT}@${USER}:${PASS}"
WS_SSL="${HOST}:${WSS_PORT}@${USER}:${PASS}"

if [[ -n "$DROPBEAR_PORTS" ]]; then
    DB_CONN="${HOST}:$(echo "$DROPBEAR_PORTS" | cut -d',' -f1)@${USER}:${PASS}"
else
    DB_CONN=""
fi

SSH_UDP="${IP}:1-65535@${USER}:${PASS}"
#==================================================
# PANEL PREMIUM
#==================================================

clear

# Detectar port of Hysteria
HYSTERIA_PORT=$(grep -oP '"listen":\s*":\K[0-9]+' /etc/hysteria/config.json 2>/dev/null)
[[ -z "$HYSTERIA_PORT" ]] && HYSTERIA_PORT="Not installed"

# Detectar OBFS
HYSTERIA_OBFS=$(grep -oP '"obfs":\s*"\K[^"]+' /etc/hysteria/config.json 2>/dev/null)
[[ -z "$HYSTERIA_OBFS" ]] && HYSTERIA_OBFS="Not configured"

#========================#
# DETECTAR PUERTO ZIVPN
#========================#

if [[ -f /etc/zivpn/config.json ]] && command -v jq >/dev/null 2>&1; then

    ZIVPN_PORT=$(jq -r '.listen // empty' /etc/zivpn/config.json 2>/dev/null | tr -d ':')

else

    ZIVPN_PORT=""

fi

[[ -z "$ZIVPN_PORT" ]] && ZIVPN_PORT="Not installed"

HOST="${SERVER_DOMAIN:-$IP}"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${MAGENTA}               ⚜ CUENTA SSH CREADA EXITOSAMENTE ⚜            ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo
echo -e "${YELLOW}══════════ DATOS DEL USER ══════════${RESET}"
echo -e " ${WHITE}User      : ${GREEN}$USER${RESET}"
echo -e " ${WHITE}Password   : ${GREEN}$PASS${RESET}"
echo -e " ${WHITE}Expires       : ${GREEN}$FECHA${RESET} ${GRAY}(${DIAS} days)${RESET}"
echo -e " ${WHITE}Limit IP    : ${GREEN}$LIMITE_MOSTRAR${RESET}"
echo
echo -e "${YELLOW}══════════ SERVER INFORMATION ══════════${RESET}"
echo -e " ${WHITE}Host/IP      : ${CYAN}$HOST${RESET}"
echo -e " ${WHITE}SSH          : ${GREEN}$SSH_PORTS${RESET}"
echo -e " ${WHITE}Dropbear     : ${GREEN}${DROPBEAR_PORTS:-Not installed}${RESET}"
echo -e " ${WHITE}SSL Tunnel   : ${GREEN}${HAPROXY_PORTS:-Not installed}${RESET}"
echo -e " ${WHITE}OpenVPN      : ${GREEN}1194,2200,443${RESET}"
echo -e " ${WHITE}BadVPN       : ${GREEN}${BADVPN_PORTS:-Not installed}${RESET}"
echo
echo -e "${YELLOW}══════════ HTTP CUSTOM ══════════${RESET}"
echo -e " ${GREEN}${HOST}:443@${USER}:${PASS}${RESET}"
echo -e " ${GREEN}${HOST}:80@${USER}:${PASS}${RESET}"
echo -e " ${GREEN}${HOST}:8080@${USER}:${PASS}${RESET}"
echo
echo -e "${YELLOW}══════════ UDP CUSTOM ══════════${RESET}"
echo -e " ${GREEN}${HOST}:1-65535@${USER}:${PASS}${RESET}"
echo
echo -e "${YELLOW}══════════ HYSTERIA V1 ══════════${RESET}"
echo -e " ${WHITE}Server     : ${GREEN}${HOST}:${HYSTERIA_PORT}${RESET}"
echo -e " ${WHITE}OBFS         : ${GREEN}${HYSTERIA_OBFS}${RESET}"
echo -e " ${WHITE}Credenciales : ${GREEN}${USER}:${PASS}${RESET}"
echo
echo -e "${YELLOW}══════════ ZIVPN UDP ══════════${RESET}"
echo -e " ${WHITE}Server     : ${GREEN}${HOST}:${ZIVPN_PORT}${RESET}"
echo -e " ${WHITE}Password   : ${GREEN}${PASS}${RESET}"
echo -e " ${WHITE}Port UDP   : ${GREEN}20000-29999${RESET}"

# Show SlowDNS only if it exists
if [[ -f /etc/slowdns/domain.conf && -f /etc/slowdns/server.pub ]]; then
    SLOWDNS_NS=$(cat /etc/slowdns/domain.conf)
    SLOWDNS_KEY=$(cat /etc/slowdns/server.pub)

    echo
    echo -e "${YELLOW}══════════ SLOWDNS (5300) ══════════${RESET}"
    echo -e " ${WHITE}NS          : ${GREEN}${SLOWDNS_NS}${RESET}"
    echo -e " ${WHITE}KEY         : ${GREEN}${SLOWDNS_KEY}${RESET}"
fi

echo
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${YELLOW}          Press ENTER to continue...${RESET}"
read

exec bash "$BASE/users/menu.sh"
done
