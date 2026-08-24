#!/bin/bash

#=========================================================
#        ORX TUNNEL UPDATER
#        License key update system
#        LICENSE API v2.2
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

LICENSE_API="https://usa.socialstreaming.xyz"

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
# LICENSE VARIABLES
#=========================================================

INSTALL_KEY=""

LICENSE_OWNER=""
LICENSE_RESELLER=""
LICENSE_TYPE="normal"
LICENSE_DELETE_AT=""

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
echo -e " ${GRAY}➜${RESET} License API: ${SKY}$LICENSE_API${RESET}"

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
# VERIFICAR SERVER LICENSE
#=========================================================

echo -e "${GOLD}${BOLD}◆ SERVER LICENSE${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

info "Checking API..."

HEALTH_RESPONSE="$(
    curl \
        --silent \
        --show-error \
        --connect-timeout 5 \
        --max-time 15 \
        -4 \
        -w '\n%{http_code}' \
        "${LICENSE_API}/health" \
        2>/dev/null
)"

HEALTH_HTTP="$(
    printf '%s\n' "$HEALTH_RESPONSE" |
    tail -n1
)"

HEALTH_BODY="$(
    printf '%s\n' "$HEALTH_RESPONSE" |
    sed '$d'
)"

if [[ "$HEALTH_HTTP" != "200" ]]; then

    error "Server of the license not available."

    echo
    echo -e "${GRAY}HTTP: $HEALTH_HTTP${RESET}"
    echo

    exit 1

fi

if ! echo "$HEALTH_BODY" |
    jq -e '.ok == true' >/dev/null 2>&1; then

    error "The API of the license returned an invalid status."

    echo
    echo "$HEALTH_BODY"
    echo

    exit 1

fi

ok "Server of the license available."

echo

#=========================================================
# LICENSE
#=========================================================

echo -e "${GOLD}${BOLD}◆ UPDATE AUTHORIZATION${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

echo -e " ${YELLOW}🔐 This update requiere a valid key.${RESET}"
echo -e " ${GRAY}The key will be validated through the API public.${RESET}"
echo

while true; do

    read -r -p " 🔑 Enter your installation key: " INSTALL_KEY

    INSTALL_KEY="$(
        printf '%s' "$INSTALL_KEY" |
        tr -d '[:space:]'
    )"

    if [[ -z "$INSTALL_KEY" ]]; then

        error "The key cannot estar empty."
        echo

        continue

    fi

    echo

    info "Verifying license..."

    #=====================================================
    # JSON
    #=====================================================

    VALIDATE_JSON="$(
        jq -n \
            --arg key "$INSTALL_KEY" \
            '{
                key: $key
            }'
    )"

    #=====================================================
    # API VALIDATE
    #=====================================================

    VALIDATE_RESPONSE="$(
        curl \
            --silent \
            --show-error \
            --connect-timeout 5 \
            --max-time 15 \
            -4 \
            -w '\n%{http_code}' \
            -X POST \
            -H "Content-Type: application/json" \
            --data "$VALIDATE_JSON" \
            "${LICENSE_API}/api/public/validate" \
            2>/dev/null
    )"

    CURL_STATUS=$?

    VALIDATE_HTTP="$(
        printf '%s\n' "$VALIDATE_RESPONSE" |
        tail -n1
    )"

    VALIDATE_BODY="$(
        printf '%s\n' "$VALIDATE_RESPONSE" |
        sed '$d'
    )"

    #=====================================================
    # CONNECTION ERROR
    #=====================================================

    if [[ "$CURL_STATUS" -ne 0 ]]; then

        error "Could not connect with the API."

        echo
        echo -e "${YELLOW}Check your Internet connection.${RESET}"
        echo

        sleep 2

        continue

    fi

    #=====================================================
    # HTTP VALIDATION
    #=====================================================

    if [[ "$VALIDATE_HTTP" != "200" ]]; then

        error "The validation API returned HTTP $VALIDATE_HTTP."

        echo
        echo -e "${GRAY}Respuesta:${RESET}"
        echo "$VALIDATE_BODY"
        echo

        sleep 2

        continue

    fi

    #=====================================================
    # JSON VALID
    #=====================================================

    if ! echo "$VALIDATE_BODY" |
        jq empty >/dev/null 2>&1; then

        error "The API returned an invalid response."

        echo
        echo -e "${GRAY}HTTP: $VALIDATE_HTTP${RESET}"
        echo

        sleep 2

        continue

    fi

    #=====================================================
    # RESULTADO
    #=====================================================

    VALID="$(
        echo "$VALIDATE_BODY" |
        jq -r '.ok // .valid // false'
    )"

    ERROR_CODE="$(
        echo "$VALIDATE_BODY" |
        jq -r '.error // empty'
    )"

    #=====================================================
    # KEY INVALID
    #=====================================================

    if [[ "$VALID" != "true" ]]; then

        echo

        case "$ERROR_CODE" in

            key_not_found)

                error "The key does not exist."

                ;;

            key_used)

                error "The key was already used."

                ;;

            key_expired)

                error "The key has expired."

                ;;

            key_required)

                error "No ... received a Key."

                ;;

            *)

                error "The key is not valid."

                ;;

        esac

        echo
        echo -e "${YELLOW}The update will not continue.${RESET}"
        echo

        sleep 2

        continue

    fi

    #=====================================================
    # DATOS
    #=====================================================

    LICENSE_OWNER="$(
        echo "$VALIDATE_BODY" |
        jq -r '.owner // "Desconocido"'
    )"

    LICENSE_RESELLER="$(
        echo "$VALIDATE_BODY" |
        jq -r '.reseller // "Desconocido"'
    )"

    LICENSE_TYPE="$(
        echo "$VALIDATE_BODY" |
        jq -r '.type // "normal"'
    )"

    LICENSE_DELETE_AT="$(
        echo "$VALIDATE_BODY" |
        jq -r '.deleteAt // empty'
    )"

    #=====================================================
    # MOSTRAR LICENSE
    #=====================================================

    echo

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}              ✅ VALID LICENSE${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo

    echo -e " ${GRAY}Propietario:${RESET} ${WHITE}${LICENSE_OWNER}${RESET}"
    echo -e " ${GRAY}Revendedor :${RESET} ${WHITE}${LICENSE_RESELLER}${RESET}"
    echo -e " ${GRAY}Tipo       :${RESET} ${WHITE}${LICENSE_TYPE}${RESET}"

    if [[ -n "$LICENSE_DELETE_AT" &&
          "$LICENSE_DELETE_AT" != "null" ]]; then

        echo -e " ${GRAY}Expires     :${RESET} ${WHITE}${LICENSE_DELETE_AT}${RESET}"

    fi

    echo

    ok "License authorized to continue."

    echo

    break

done

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

while IFS= read -r FILE || [[ -n "$FILE" ]]; do
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

if [[ -f "$BASE/license.conf" ]]; then

    chmod 600 "$BASE/license.conf" >/dev/null 2>&1 || true

fi

ok "Permisos updated."

#=========================================================
# ACTIVATION
#=========================================================

echo

echo -e "${GOLD}${BOLD}◆ REGISTRANDO UPDATE${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

info "Registering update en License API..."

ACTIVATION_JSON="$(
    jq -n \
        --arg key "$INSTALL_KEY" \
        --arg ip "$CLIENT_IP" \
        --arg hostname "$HOSTNAME_SERVER" \
        --arg os "$OS_NAME" \
        --arg date "$DATE_NOW" \
        --arg version "$NEW_VERSION" \
        '{
            key: $key,
            ip: $ip,
            hostname: $hostname,
            os: $os,
            date: $date,
            version: $version
        }'
)"

ACTIVATE_RESPONSE="$(
    curl \
        --silent \
        --show-error \
        --connect-timeout 5 \
        --max-time 15 \
        -4 \
        -w '\n%{http_code}' \
        -X POST \
        -H "Content-Type: application/json" \
        --data "$ACTIVATION_JSON" \
        "${LICENSE_API}/api/public/activate" \
        2>/dev/null
)"

ACTIVATE_STATUS=$?

ACTIVATE_HTTP="$(
    printf '%s\n' "$ACTIVATE_RESPONSE" |
    tail -n1
)"

ACTIVATE_BODY="$(
    printf '%s\n' "$ACTIVATE_RESPONSE" |
    sed '$d'
)"

#=========================================================
# ERROR CONNECTION
#=========================================================

if [[ "$ACTIVATE_STATUS" -ne 0 ]]; then

    echo

    error "Could not connect with the API of activation."

    echo
    warning "The update was installed."
    warning "The key was NOT marked as used."

    echo
    echo -e "${YELLOW}IMPORTANTE:${RESET}"
    echo -e "${WHITE}The update necesita ser registrada manualmente.${RESET}"
    echo

    rm -rf "$TMP"

    exit 1

fi

#=========================================================
# JSON
#=========================================================

if ! echo "$ACTIVATE_BODY" |
    jq empty >/dev/null 2>&1; then

    error "The API returned an invalid response."

    echo
    echo -e "${GRAY}HTTP: $ACTIVATE_HTTP${RESET}"
    echo
    echo "$ACTIVATE_BODY"
    echo

    rm -rf "$TMP"

    exit 1

fi

#=========================================================
# RESULTADO API
#=========================================================

ACTIVATE_OK="$(
    echo "$ACTIVATE_BODY" |
    jq -r '.ok // false'
)"

ACTIVATE_ERROR="$(
    echo "$ACTIVATE_BODY" |
    jq -r '.error // empty'
)"

#=========================================================
# VALIDATION DE ACTIVATION
#
# The API puede dereturn:
#
# HTTP 200 = correcto
# HTTP 201 = activation created successfully
#
# La response {"ok":true} tiene prioridad.
#=========================================================

if [[ "$ACTIVATE_OK" != "true" ]]; then

    echo

    error "Could not registrar the update."

    echo
    echo -e "${YELLOW}Code: ${ACTIVATE_ERROR:-unknown}${RESET}"
    echo -e "${YELLOW}HTTP  : $ACTIVATE_HTTP${RESET}"

    echo

    echo -e "${GRAY}Respuesta:${RESET}"
    echo "$ACTIVATE_BODY"

    echo

    warning "The update was already installed."
    warning "The key was NOT consumed."

    echo

    rm -rf "$TMP"

    exit 1

fi

#=========================================================
# ACTIVATION CORRECTA
#=========================================================

ACTIVATION_ID="$(
    echo "$ACTIVATE_BODY" |
    jq -r '.activationId // empty'
)"

echo

ok "Server of activation responded successfully."
echo -e " ${GRAY}HTTP:${RESET} ${GREEN}${ACTIVATE_HTTP}${RESET}"

echo

ok "Update registrada successfully."

if [[ -n "$ACTIVATION_ID" ]]; then

    echo
    echo -e " ${GRAY}Activation ID:${RESET} ${WHITE}$ACTIVATION_ID${RESET}"

fi

echo
ok "The API marked the key as used."

#=========================================================
# LIMPIAR MEMORIA
#=========================================================

unset INSTALL_KEY
unset ACTIVATION_JSON
unset ACTIVATE_RESPONSE
unset VALIDATE_JSON
unset VALIDATE_RESPONSE

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

echo -e " ${CYAN}◆${RESET} ${WHITE}License:${RESET} ${GREEN}ACTIVADA${RESET}"
echo -e " ${CYAN}◆${RESET} ${WHITE}Propietario:${RESET} ${WHITE}${LICENSE_OWNER}${RESET}"
echo -e " ${CYAN}◆${RESET} ${WHITE}Revendedor:${RESET} ${WHITE}${LICENSE_RESELLER}${RESET}"

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