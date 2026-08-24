#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#           ORX TUNNEL MULTI SCRIPT             #
#             DROPBEAR MANAGER                 #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

BASE="/etc/orx-tunnel"
CONFIG="$BASE/config.conf"

[[ ! -f "$CONFIG" ]] && {
    echo "Not found the file of configuration."
    exit 1
}

source "$CONFIG"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#                  COLORES                     #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

CYAN="\e[1;96m"
GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"
RESET="\e[0m"

SERVICE="dropbear_custom"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#                  FUNCIONES                   #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

line() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

ok() {
    echo -e "${GREEN}✔ $1${RESET}"
}

error() {
    echo -e "${RED}✘ $1${RESET}"
}

info() {
    echo -e "${CYAN}➜ $1${RESET}"
}

pause() {
    echo ""
    read -n1 -r -p "Press any key to continue..."
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             GET INFORMATION              #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

get_status() {

    if systemctl is-active --quiet "$SERVICE"; then
        STATUS="${GREEN}🟢 ACTIVE${RESET}"
    else
        STATUS="${RED}🔴 STOPPED${RESET}"
    fi

}

get_ports() {

    PORTS=$(systemctl cat "$SERVICE" 2>/dev/null | \
        grep ExecStart | \
        grep -oP '(?<=-p )\d+' | \
        paste -sd "," -)

    [[ -z "$PORTS" ]] && PORTS="-"

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             INSTALL DROPBEAR                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

install_dropbear() {

    clear
    line
    echo -e "${WHITE}        INSTALL DROPBEAR${RESET}"
    line

    # Default ports
    PORTS="90,143,109"

    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

    for PORT in "${PORT_ARRAY[@]}"; do

        if ss -lnt | awk '{print $4}' | grep -q ":$PORT$"; then
            error "El port $PORT ya is en uso."
            pause
            return
        fi

    done

    info "Updating repositories..."
    apt-get update

    info "Installing Dropbear..."
    apt-get install -y dropbear

    mkdir -p /etc/dropbear

    if [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]]; then
        info "Generando llave RSA..."
        dropbearkey -t rsa \
            -f /etc/dropbear/dropbear_rsa_host_key
    fi

    if [[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]]; then
        info "Generando llave ECDSA..."
        dropbearkey -t ecdsa \
            -f /etc/dropbear/dropbear_ecdsa_host_key
    fi



    systemctl stop dropbear 2>/dev/null
    systemctl disable dropbear 2>/dev/null

    EXEC="/usr/sbin/dropbear -F"

    for PORT in "${PORT_ARRAY[@]}"; do
        EXEC="$EXEC -p $PORT"
    done

    EXEC="$EXEC -W 65536 -b /etc/issue.net"

cat > /etc/systemd/system/dropbear_custom.service <<EOF
[Unit]
Description=ORX Tunnel Dropbear Multi-Port
After=network.target

[Service]
Type=simple
ExecStart=$EXEC
Restart=always
RestartSec=3
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dropbear_custom
    systemctl restart dropbear_custom

    if systemctl is-active --quiet dropbear_custom; then

        if grep -q "^DROPBEAR=" "$CONFIG"; then
            sed -i 's/^DROPBEAR=.*/DROPBEAR=ON/' "$CONFIG"
        else
            echo "DROPBEAR=ON" >> "$CONFIG"
        fi

        if grep -q "^DROPBEAR_PORT=" "$CONFIG"; then
            sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=\"$PORTS\"/" "$CONFIG"
        else
            echo "DROPBEAR_PORT=\"$PORTS\"" >> "$CONFIG"
        fi

        source "$CONFIG"

        line
        ok "Dropbear installed successfully."
        echo ""
        echo " Service : dropbear_custom"
        echo " Ports  : $PORTS"
        echo " Banner   : $BANNER"
        line

    else

        error "Could not start Dropbear."

    fi

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            REINICIAR SERVICE                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

restart_dropbear() {

    systemctl restart dropbear_custom

    if systemctl is-active --quiet dropbear_custom; then
        ok "Service restarted successfully."
    else
        error "Could not restart the service."
    fi

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#             INFORMATION COMPLETA             #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

status_dropbear() {

    clear

    get_status
    get_ports

    line
    echo -e "${WHITE}          STATUS DROPBEAR${RESET}"
    line

    echo "Status      : $STATUS"
    echo "Service    : dropbear_custom"
    echo "Ports     : $PORTS"
    echo "Banner      : /etc/issue.net"

    echo ""

    echo "Proceso"

    systemctl status dropbear_custom --no-pager -l

    pause

}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#            DESINSTALL DROPBEAR              #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

remove_dropbear() {

    clear
    line
    echo -e "${WHITE}       DESINSTALL DROPBEAR${RESET}"
    line
    echo ""

    read -rp "Do you want to continue? [y/N]: " R

    [[ ! "$R" =~ ^[Ss]$ ]] && return

    info "Deteniendo services..."

    systemctl stop dropbear_custom 2>/dev/null
    systemctl disable dropbear_custom 2>/dev/null

    systemctl stop dropbear 2>/dev/null
    systemctl disable dropbear 2>/dev/null

    info "Deletendo service personalizado..."

    rm -f /etc/systemd/system/dropbear_custom.service

    systemctl daemon-reload
    systemctl reset-failed

    info "Desinstalling paquete..."

    apt-get purge -y dropbear

    apt-get autoremove -y

    info "Limpiando files..."

    rm -rf /etc/dropbear


    if grep -q "^DROPBEAR=" "$CONFIG"; then
        sed -i 's/^DROPBEAR=.*/DROPBEAR=OFF/' "$CONFIG"
    else
        echo "DROPBEAR=OFF" >> "$CONFIG"
    fi

    sed -i '/^DROPBEAR_PORT=/d' "$CONFIG"

    source "$CONFIG"

    line
    ok "Dropbear was deleted successfully."
    line

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          VERIFICAR CONFIGURATION             #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

check_dropbear() {

    clear

    line
    echo -e "${WHITE}      DIAGNOSTICS DROPBEAR${RESET}"
    line

    echo ""

    if command -v dropbear >/dev/null 2>&1; then
        ok "Dropbear installed"
    else
        error "Dropbear is not installed"
    fi

    if systemctl is-active --quiet dropbear_custom; then
        ok "Service active"
    else
        error "Service stopped"
    fi

    if [[ -f /etc/systemd/system/dropbear_custom.service ]]; then
        ok "Service personalizado found"
    else
        error "Service personalizado does not exist"
    fi

    if [[ -f /etc/dropbear/dropbear_rsa_host_key ]]; then
        ok "Llave RSA encontrada"
    else
        error "Llave RSA inexistente"
    fi

    if [[ -f /etc/dropbear/dropbear_ecdsa_host_key ]]; then
        ok "Llave ECDSA encontrada"
    else
        error "Llave ECDSA inexistente"
    fi

    if [[ -f /etc/issue.net ]]; then
        ok "Banner found"
    else
        error "Banner inexistente"
    fi

    echo ""
    info "Ports escuchando"

    ss -lntp | grep dropbear

    pause

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#          VER INFORMATION DEL SISTEMA         #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

system_info() {

    clear

    line
    echo -e "${WHITE}        SERVER INFORMATION${RESET}"
    line

    echo ""

    echo "Hostname : $(hostname)"
    echo "Kernel   : $(uname -r)"
    echo "System  : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"

    echo ""

    echo "IP Local"

    hostname -I

    echo ""

    echo "Uso of memoria"

    free -h

    echo ""

    echo "Espacio en disco"

    df -h /

    pause

}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#               AUTOMATIC MODE                #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

if [[ "$1" == "--auto" ]]; then
    echo "🚀 Installing Dropbear automatically..."

    install_dropbear

    if systemctl is-active --quiet dropbear_custom; then
        echo "✅ Dropbear installed successfully."
        exit 0
    else
        echo "❌ Error installing Dropbear."
        exit 1
    fi
fi
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#
#                  MENU                        #
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#

while true; do

    clear

    get_status
    get_ports

    line
    echo -e "${WHITE}            🔐 DROPBEAR MANAGER${RESET}"
    line

    echo -e " Status     : $STATUS"
    echo -e " Service   : $SERVICE"
    echo -e " Ports    : $PORTS"
    echo -e " Installed  : ${DROPBEAR:-OFF}"

    line

    if [[ "$DROPBEAR" == "ON" ]]; then

        cat <<EOF
 [1] Reinstall Dropbear
 [2] Restart Service
 [3] Status of the Service
 [4] Diagnostics
 [5] Information of the Server
 [6] Uninstall Dropbear
 [0] Return
EOF

    else

        cat <<EOF
 [1] Install Dropbear
 [0] Return
EOF

    fi

    line

    read -rp " ► Option: " OP

case "$OP" in

1)
    install_dropbear
;;

2)
    restart_dropbear
;;

3)
    status_dropbear
;;

4)
    check_dropbear
;;

5)
    system_info
;;

6)
    remove_dropbear
;;

0)
    exec bash "$BASE/protocols/menu.sh"
;;

*)
    error "Option invalid."
    sleep 2
;;

esac
done
