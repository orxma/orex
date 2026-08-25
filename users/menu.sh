#!/bin/bash

# =========================================================
#             ORX TUNNEL MULTI SCRIPT
#              SSH ADMINISTRATION PANEL
# =========================================================

BASE="/etc/orx-tunnel"
VERSION="2.0"

# =========================
# COLORES
# =========================

RESET="\e[0m"
BOLD="\e[1m"

CYAN="\e[1;96m"
BLUE="\e[1;94m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
MAGENTA="\e[1;95m"
RED="\e[1;91m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

# =========================
# FUNCIONES
# =========================

line() {
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
}

title() {
    echo -e "${CYAN}║${RESET} ${MAGENTA}${BOLD}$1${RESET}"
}

pause() {
    echo
    read -rp "$(echo -e "${GRAY}Press ENTER to continue...${RESET}")"
}

run_module() {

    local file="$1"

    if [[ ! -f "$BASE/users/$file" ]]; then
        echo
        echo -e "${RED}✘ Module not found:${RESET}"
        echo -e "${GRAY}$BASE/users/$file${RESET}"
        pause
        return
    fi

    bash "$BASE/users/$file"

    echo
    pause
}

# =========================
# SERVER INFORMATION
# =========================

get_cpu() {

    local cpu

    cpu=$(top -bn1 2>/dev/null |
        awk '/Cpu\(s\)/ {
            for(i=1;i<=NF;i++) {
                if($i ~ /id,/) {
                    gsub(",", "", $(i-1))
                    printf "%.0f", 100-$(i-1)
                    exit
                }
            }
        }')

    [[ -z "$cpu" ]] && cpu="0"

    echo "${cpu}%"
}

get_ram() {

    free -h 2>/dev/null |
        awk '/Mem:/ {print $3 "/" $2}'
}

get_disk() {

    df -h / 2>/dev/null |
        awk 'NR==2 {print $5}'
}

get_users() {

    who 2>/dev/null | wc -l
}

get_ip() {

    hostname -I 2>/dev/null | awk '{print $1}'
}

get_uptime() {

    uptime -p 2>/dev/null |
        sed 's/^up //'
}

# =========================
# SERVICE STATUS
# =========================

service_status() {

    local service="$1"

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}● ACTIVE${RESET}"
    else
        echo -e "${RED}● INACTIVE${RESET}"
    fi
}

# =========================
# CABECERA
# =========================

show_header() {

    local hostname
    local ip
    local ram
    local cpu
    local disk
    local users
    local uptime

    hostname=$(hostname 2>/dev/null)
    ip=$(get_ip)
    ram=$(get_ram)
    cpu=$(get_cpu)
    disk=$(get_disk)
    users=$(get_users)
    uptime=$(get_uptime)

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}             ${MAGENTA}${BOLD}🛡️  ORX TUNNEL MULTI SCRIPT${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                  ${GRAY}SSH ADMIN PANEL${RESET}                  ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

    printf "${CYAN}║${RESET} ${WHITE}🖥 SERVER${RESET} %-18s ${WHITE}🌐 IP${RESET} %-18s${CYAN}║${RESET}\n" \
        "${hostname:0:18}" "${ip:0:18}"

    printf "${CYAN}║${RESET} ${WHITE}⏱ UPTIME${RESET}  %-18s ${WHITE}👥 SSH${RESET} %-18s${CYAN}║${RESET}\n" \
        "${uptime:0:18}" "$users"

    line

    printf "${CYAN}║${RESET} ${WHITE}💾 RAM${RESET} %-10s ${WHITE}⚡ CPU${RESET} %-7s ${WHITE}💿 DISCO${RESET} %-7s ${CYAN}║${RESET}\n" \
        "$ram" "$cpu" "$disk"

    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
}

# =========================
# OPTION
# =========================

option() {

    printf "  ${GREEN}${BOLD}[%02d]${RESET} ${WHITE}%-3s %-35s${RESET}\n" \
        "$1" "$2" "$3"
}

# =========================
# VERIFICAR ROOT
# =========================

if [[ $EUID -ne 0 ]]; then

    clear

    echo
    echo -e "${RED}${BOLD}✘ ACCESO DENEGADO${RESET}"
    echo
    echo -e "${WHITE}Este panel requiere permisos of root.${RESET}"
    echo
    echo -e "${YELLOW}Run:${RESET}"
    echo -e "${GREEN}sudo bash $0${RESET}"
    echo

    exit 1
fi

# =========================
# MAIN MENU
# =========================

while true; do

    clear

    show_header

    echo
    echo -e "${BLUE}${BOLD}  🔐 SSH USER MANAGEMENT${RESET}"
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────${RESET}"

    option 1  "👤" "Create SSH User"
    option 2  "🗑️" "Delete User"
    option 3  "♻️" "Renew / Edit User"
    option 4  "📋" "User List"
    option 5  "🌐" "Connected Users"

    echo
    echo -e "${BLUE}${BOLD}  🛡️ SECURITY AND CONFIGURATION${RESET}"
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────${RESET}"

    option 6  "📢" "Banner SSH / Dropbear"
    option 7  "🔒" "Block / Unblock"
    option 8  "💾" "User Backup"

    echo
    echo -e "${BLUE}${BOLD}  ⚙️ SISTEMA${RESET}"
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────${RESET}"

    option 9  "🔄" "Update ORX Tunnel"
    option 10 "📊" "Information of the Server"

    echo
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────${RESET}"

    echo -e "  ${RED}${BOLD}[00]${RESET} 🚪 ${WHITE}Return to the Menu Principal${RESET}"

    echo
    echo -e "${GRAY}  ORX TUNNEL Multi Script • v${VERSION}${RESET}"
    echo

    read -rp "$(echo -e "${CYAN}${BOLD}  ➜ Select an option:${RESET} ")" op

    case "$op" in

        1)
            run_module "add.sh"
            ;;

        2)
            run_module "delete.sh"
            ;;

        3)
            run_module "edit.sh"
            ;;

        4)
            run_module "list.sh"
            ;;

        5)
            run_module "online.sh"
            ;;

        6)
            run_module "banner.sh"
            ;;

        7)
            run_module "block.sh"
            ;;

        8)
            run_module "backup.sh"
            ;;

        9)

            clear

            echo
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${CYAN}║${RESET}              ${MAGENTA}${BOLD}🔄 UPDATE ORX TUNNEL${RESET}              ${CYAN}║${RESET}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
            echo

            if [[ -f "$BASE/update.sh" ]]; then
                bash "$BASE/update.sh"
            else
                echo -e "${YELLOW}⚠ El updater is not installed.${RESET}"
            fi

            pause
            ;;

        10)

            clear

            echo
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${CYAN}║${RESET}              ${MAGENTA}${BOLD}📊 SERVER INFORMATION${RESET}             ${CYAN}║${RESET}"
            echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

            echo -e "${WHITE}🖥 Hostname     :${RESET} ${GREEN}$(hostname)${RESET}"
            echo -e "${WHITE}🌐 IP           :${RESET} ${GREEN}$(get_ip)${RESET}"
            echo -e "${WHITE}🧠 Kernel       :${RESET} ${GREEN}$(uname -r)${RESET}"
            echo -e "${WHITE}💻 Arquitectura :${RESET} ${GREEN}$(uname -m)${RESET}"
            echo -e "${WHITE}🐧 System      :${RESET} ${GREEN}$(. /etc/os-release && echo "$PRETTY_NAME")${RESET}"
            echo -e "${WHITE}⏱ Uptime       :${RESET} ${GREEN}$(get_uptime)${RESET}"
            echo -e "${WHITE}💾 RAM          :${RESET} ${GREEN}$(get_ram)${RESET}"
            echo -e "${WHITE}⚡ CPU          :${RESET} ${GREEN}$(get_cpu)${RESET}"
            echo -e "${WHITE}💿 Disco        :${RESET} ${GREEN}$(get_disk)${RESET}"
            echo -e "${WHITE}👥 SSH Online   :${RESET} ${GREEN}$(get_users)${RESET}"

            echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

            echo -e "${WHITE}🔐 SSH:${RESET}      $(service_status ssh)"
            echo -e "${WHITE}🛡️ Dropbear:${RESET} $(service_status dropbear)"

            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

            pause
            ;;

        0)

            clear

            echo
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${CYAN}║${RESET} ${GREEN}${BOLD}        ✔ EXITING ORX TUNNEL MULTI SCRIPT${RESET}        ${CYAN}║${RESET}"
            echo -e "${CYAN}║${RESET}              ${GRAY}Gracias by utilizar el panel${RESET}              ${CYAN}║${RESET}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
            echo

            sleep 1

            exec bash "$BASE/menu.sh"
            ;;

        *)

            echo
            echo -e "  ${RED}${BOLD}✘ Option invalid${RESET}"
            sleep 1
            ;;

    esac

done