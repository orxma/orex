#!/bin/bash

#==================================================
# ORX Tunnel Multi Script
# CheckUser
#==================================================

BASE="/etc/orx-tunnel"

GREEN="\e[1;92m"
RED="\e[1;91m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
CYAN="\e[1;96m"
MAGENTA="\e[1;95m"
WHITE="\e[1;97m"
RESET="\e[0m"

check_installed() {
    [[ -f /usr/lib/chall/chall.sh ]]
}
status_checkuser() {
    if [[ -f /usr/lib/chall/chall.sh ]]; then
        echo -e "${GREEN}🟢 ACTIVE${RESET}"
    else
        echo -e "${RED}🔴 OFF${RESET}"
    fi
}
      #===============================
# ONLINE APP
#===============================

function onapp1() {
    clear
    echo -e "\n\033[1;32mINICIANDO O ONLINE APP... \033[0m"
    echo ""

    apt install apache2 -y > /dev/null 2>&1

    sed -i "s/Listen 80/Listen 8888/g" /etc/apache2/ports.conf >/dev/null 2>&1

    service apache2 restart

    rm -rf /var/www/html/server >/dev/null 2>&1
    mkdir -p /var/www/html/server >/dev/null 2>&1

    chmod +x "$BASE/protocols/onlineapp"
screen -dmS onlineapp "$BASE/protocols/onlineapp"
sleep 3

    if [[ $(grep -wc "onlineapp" /etc/autostart) = '0' ]]; then
        echo "ps x | grep '$BASE/protocols/onlineapp' | grep -v grep >/dev/null || screen -dmS onlineapp $BASE/protocols/onlineapp" >> /etc/autostart
    else
        sed -i '/onlineapp/d' /etc/autostart
        echo "ps x | grep '$BASE/protocols/onlineapp' | grep -v grep >/dev/null || screen -dmS onlineapp $BASE/protocols/onlineapp" >> /etc/autostart
    fi

    IP=$(wget -qO- ipv4.icanhazip.com)

    echo ""
    echo -e "\033[1;32mONLINE APP ATIVO!\033[0m"
    echo -e "\033[1;33mURL of Users Online:\033[0m"
    echo "http://$IP:8888/server/online"

    sleep 10

}

function onapp2() {
    clear
    echo -e "\n\033[1;31mPARANDO O ONLINE APP... \033[0m"
    echo ""

    fun_stponlineapp() {

        service apache2 stop >/dev/null 2>&1

        screen -S onlineapp -X quit >/dev/null 2>&1
        pkill -f "$BASE/protocols/onlineapp" >/dev/null 2>&1

        screen -wipe >/dev/null 2>&1

        sed -i '/onlineapp/d' /etc/autostart

        rm -rf /var/www/html/server >/dev/null 2>&1
    }

    fun_stponlineapp
sleep 3

    echo ""
    echo -e "\033[1;31mONLINE APP PARADO!\033[0m"

    sleep 3

}

function onapp_ssh() {
    if pgrep -f "onlineapp" >/dev/null; then
        onapp2
    else
        onapp1
    fi
}

while true; do
    clear

    CHECKUSER_STATUS=$
(status_checkuser)

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${MAGENTA}           🛡 ORX Tunnel Multi Script${RESET}"
    echo -e "${WHITE}               MENU CHECKUSER${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    printf " ${GREEN}[01]${RESET} 👤 CheckUser Multi-Apps    %b\n" "$CHECKUSER_STATUS"
    echo -e " ${GREEN}[02]${RESET} 🌐 CheckUser DTunnel"
    echo -e " ${GREEN}[03]${RESET} 🚀 CheckUser DTunnel-Go"
    echo -e " ${GREEN}[04]${RESET} 🔗 online app"

    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e " ${GREEN}[00]${RESET} ↩ Return"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo
    read -rp " ► Option: " OP

    case "$OP" in

        1|01)
            if check_installed; then
                chall
            else
                bash <(curl -sL https://raw.githubusercontent.com/PhoenixxZ2023/checkUser2024/main/instcheck.sh)
                [[ -x "$(command -v chall)" ]] && chall
            fi
        ;;

        2|02)
            bash <(curl -sL https://raw.githubusercontent.com/PhoenixxZ2023/DTCheckUser/master/install.sh)
        ;;

        3|03)
            bash <(curl -sL https://n9.cl/yo2nc)
        ;;

        4|04)
    onapp_ssh
;;

        0|00)
            exec bash "$BASE/protocols/menu.sh"
        ;;

        *)
            echo
            echo -e "${RED}❌ Option invalid.${RESET}"
            sleep 2
        ;;
    esac
done
