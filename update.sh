#!/bin/bash

#=========================================================
#        ORX TUNNEL UPDATER
#=========================================================

set -o pipefail

#=========================================================
# VARIABLES
#=========================================================

BASE="/etc/orx-tunnel"
TMP="/tmp/orx-tunnel_update"

BASE_URL="https://sc.orx.ma"
MANIFEST_URL="${BASE_URL}/manifest.txt"

VERSION_FILE="$BASE/version.txt"

#=========================================================
# COLORES
#=========================================================

RESET="\e[0m"

RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
BOLD="\e[1m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

GOLD="\e[38;5;220m"
SKY="\e[38;5;117m"
PURPLE="\e[38;5;141m"
LIME="\e[38;5;154m"

#=========================================================
# SERVER VARIABLES
#=========================================================

CLIENT_IP=""
OS_NAME=""
HOSTNAME_SERVER=""
DATE_NOW=""

VERSION_CURRENT="No available"
NEW_VERSION="No available"

#=========================================================
# FUNCIONES
#=========================================================

titulo() {

    clear 2>/dev/null || true

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${WHITE}${BOLD}                    ORX TUNNEL UPDATER${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} ${GRAY}                       VERSION 2.0.0${RESET}                ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

}

ok() {
    echo -e " ${GREEN}✔${RESET} ${WHITE}$1${RESET}"
}

info() {
    echo -e " ${CYAN}◆${RESET} ${WHITE}$1${RESET}"
}

error() {
    echo -e " ${RED}✘${RESET} ${WHITE}$1${RESET}"
}

warning() {
    echo -e " ${YELLOW}⚠${RESET} ${WHITE}$1${RESET}"
}

#=========================================================
# ERROR
#=========================================================

error_exit() {

    echo
    error "$1"
    echo

    rm -rf "$TMP"

    exit 1
}

#=========================================================
# ROOT
#=========================================================

if [[ "$EUID" -ne 0 ]]; then

    echo -e "${RED}❌ This updater must be run as root.${RESET}"
    echo

    if command -v sudo >/dev/null 2>&1; then

        exec sudo bash "$0" "$@"

    else

        exit 1

    fi

fi

#=========================================================
# COMPROBAR INSTALLATION
#=========================================================

if [[ ! -d "$BASE" ]]; then

    error "The directory $BASE."

    echo
    echo -e "${YELLOW}⚠ The system ORX Tunnel does not appear to be installed.${RESET}"
    echo

    exit 1

fi

# Remove legacy license metadata from existing installations.
rm -f "$BASE/license.conf" "$BASE/license.conf.orx-tunnel.backup"

#=========================================================
# DEPENDENCIAS
#=========================================================

MISSING=""

command -v curl >/dev/null 2>&1 || MISSING+=" curl"
command -v jq >/dev/null 2>&1 || MISSING+=" jq"
command -v git >/dev/null 2>&1 || MISSING+=" git"

if [[ -n "$MISSING" ]]; then

    echo -e "${CYAN}◆ Installing dependencies:${RESET}${WHITE}$MISSING${RESET}"
    echo

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y >/dev/null 2>&1 || \
        error_exit "Could not update the repositories."

    apt-get install -y \
        curl \
        jq \
        git \
        ca-certificates \
        >/dev/null 2>&1 || \
        error_exit "Could not install the dependencies."

fi

#=========================================================
# INICIO
#=========================================================

titulo

echo -e "${GOLD}${BOLD}◆ SYSTEM UPDATE${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

info "Preparing update..."

echo -e " ${GRAY}➜${RESET} Repositorio: ${SKY}$REPO${RESET}"
echo -e " ${GRAY}➜${RESET} Destino:     ${SKY}$BASE${RESET}"

echo

#=========================================================
# VERSION INSTALADA
#=========================================================

if [[ -f "$VERSION_FILE" ]]; then

    VERSION_CURRENT="$(
        head -n1 "$VERSION_FILE" |
        tr -d '\r'
    )"

fi

[[ -z "$VERSION_CURRENT" ]] && \
    VERSION_CURRENT="No available"

echo -e "${BLUE}${BOLD}◆ VERSION INFORMATION${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

echo -e " ${YELLOW}Version installed:${RESET} ${WHITE}${VERSION_CURRENT}${RESET}"

echo

#=========================================================
# INFORMATION SERVER
#=========================================================

info "Collecting information dthe server..."

CLIENT_IP="$(
    curl \
        --silent \
        --show-error \
        --connect-timeout 5 \
        --max-time 10 \
        -4 \
        https://api.ipify.org \
        2>/dev/null
)"

if [[ -z "$CLIENT_IP" ]]; then
    CLIENT_IP="Desconocida"
fi

OS_NAME="$(
    grep '^PRETTY_NAME=' /etc/os-release |
    cut -d'"' -f2
)"

[[ -z "$OS_NAME" ]] && \
    OS_NAME="Desconocido"

HOSTNAME_SERVER="$(hostname)"

DATE_NOW="$(
    date -u '+%Y-%m-%dT%H:%M:%SZ'
)"

echo

echo -e "${CYAN}${BOLD}◆ SERVER INFORMATION${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

echo -e " ${GRAY}IP:${RESET}        ${WHITE}$CLIENT_IP${RESET}"
echo -e " ${GRAY}Hostname:${RESET}  ${WHITE}$HOSTNAME_SERVER${RESET}"
echo -e " ${GRAY}System:${RESET}   ${WHITE}$OS_NAME${RESET}"
echo -e " ${GRAY}Fecha:${RESET}     ${WHITE}$DATE_NOW${RESET}"

echo

#=========================================================
# TEMPORAL
#=========================================================

info "Preparando files temporales..."

rm -rf "$TMP"

mkdir -p "$TMP" || \
    error_exit "Could not create the directory temporal."

echo

#=========================================================
# DOWNLOAD UPDATE
#=========================================================

echo -e "${MAGENTA}${BOLD}◆ DOWNLOADING UPDATE${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

echo -e " ${CYAN}⬇${RESET} ${WHITE}Connecting to GitHub...${RESET}"
echo

if ! curl -fsSL --max-time 30 "$MANIFEST_URL" -o "$TMP/manifest.txt"; then

    echo

    error "Could not download the update manifest."

    echo
    echo -e " ${YELLOW}⚠${RESET} Comprueba:"
    echo -e "   ${GRAY}•${RESET} Connection a Internet"
    echo -e "   ${GRAY}•${RESET} Acceso a GitHub"
    echo -e "   ${GRAY}•${RESET} Availability of the repositorio"
    echo

    rm -rf "$TMP"

    exit 1

fi

# Normalize manifests served with Windows line endings before building URLs.
sed -i 's/\r$//' "$TMP/manifest.txt"

while IFS= read -r FILE || [[ -n "$FILE" ]]; do
    FILE="${FILE//$'\r'/}"
    [[ -z "$FILE" || "$FILE" == \#* ]] && continue
    mkdir -p "$TMP/$(dirname "$FILE")"
    if ! curl -fsSL --max-time 30 "${BASE_URL}/${FILE}" -o "$TMP/$FILE"; then
        rm -rf "$TMP"
        error_exit "Could not download: $FILE"
    fi
done < "$TMP/manifest.txt"

echo

ok "Update desloadda successfully."

#=========================================================
# NEW VERSION
#=========================================================

if [[ -f "$TMP/version.txt" ]]; then

    NEW_VERSION="$(
        head -n1 "$TMP/version.txt" |
        tr -d '\r'
    )"

fi

[[ -z "$NEW_VERSION" ]] && \
    NEW_VERSION="No available"

echo

echo -e "${PURPLE}${BOLD}◆ VERSION CONTROL${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

echo -e " ${YELLOW}Version current:${RESET} ${WHITE}${VERSION_CURRENT}${RESET}"
echo -e " ${GREEN}New version:${RESET}  ${LIME}${NEW_VERSION}${RESET}"

echo

#=========================================================
# BACKUP
#=========================================================

echo -e "${BLUE}${BOLD}◆ COPIA DE SEGURIDAD${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

BACKUP_DIR="${BASE}/backup"

mkdir -p "$BACKUP_DIR" || \
    error_exit "Could not create the directory of backup."

BACKUP_FILE="$BACKUP_DIR/backup_$(date '+%Y%m%d_%H%M%S').tar.gz"

info "Creating backup..."

if tar \
    -czf "$BACKUP_FILE" \
    -C "$BASE" \
    --exclude="./backup" \
    . >/dev/null 2>&1; then

    ok "Backup created."

    echo -e " ${GRAY}➜${RESET} $BACKUP_FILE"

else

    warning "Could not create the backup completo."
    echo -e "${YELLOW}The update will continue.${RESET}"

fi

echo

#=========================================================
# INSTALL
#=========================================================

echo -e "${BLUE}${BOLD}◆ INSTALANDO FILES${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

info "Copiando files..."

if ! cp -a "$TMP"/. "$BASE"/; then

    echo

    error "Could not copy los files."

    echo
    warning "The key will NOT be consumed."

    rm -rf "$TMP"

    exit 1

fi

ok "Files updated successfully."

#=========================================================
# VERSION
#=========================================================

if [[ -f "$TMP/version.txt" ]]; then

    cp -f \
        "$TMP/version.txt" \
        "$VERSION_FILE"

    ok "Version installed: ${NEW_VERSION}"

else

    warning "Not found version.txt."

fi

#=========================================================
# PERMISOS
#=========================================================

echo

info "Aplicando permisos..."

chmod -R 755 "$BASE" >/dev/null 2>&1 || true

ok "Permisos updated."

#=========================================================
# LIMPIEZA
#=========================================================

echo

info "Limpiando files temporales..."

rm -rf "$TMP"

ok "Limpieza completed."

#=========================================================
# FINAL
#=========================================================

echo

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET} ${WHITE}${BOLD}          ✅ UPDATE COMPLETED${RESET}              ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET} ${GRAY}          ORX Tunnel Multi Script Premium${RESET}           ${GREEN}║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"

echo

echo -e " ${CYAN}◆${RESET} ${WHITE}Version anterior:${RESET} ${GRAY}${VERSION_CURRENT}${RESET}"
echo -e " ${CYAN}◆${RESET} ${WHITE}Version installed:${RESET} ${GREEN}${NEW_VERSION}${RESET}"

echo

echo

echo -e "${CYAN}🚀${RESET} ${WHITE}Regresando al panel...${RESET}"

sleep 2

#=========================================================
# REGRESAR AL MENU
#=========================================================

if [[ -f "$BASE/menu.sh" ]]; then

    exec bash "$BASE/menu.sh"

else

    echo
    warning "Not found menu.sh."
    echo
    echo -e "${CYAN}Type:${RESET} menu"
    echo

fi

exit 0