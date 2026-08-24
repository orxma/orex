#!/bin/bash
set -euo pipefail

# =========================================================
# UNIVERSAL INSTALLER V8.0.5: DEPWISE TELEGRAM BOT 💎 (GO EDITION)
# =========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

if [ "$EUID" -ne 0 ]; then
  log_error "Please run this script as root"
  exit 1
fi
# Verify the system is Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        log_error "This installer is only compatible with Ubuntu."
        exit 1
    fi
else
    log_error "Could not detect the operating system."
    exit 1
fi
PROJECT_DIR="/opt/depwise_bot"
ENV_FILE="$PROJECT_DIR/.env"

install_bot() {
    echo -e "${GREEN}=================================================="
    echo -e "       DEPWISE BOT CONFIGURATION V8.0 (GO)"
    echo -e "==================================================${NC}"
        apt update -y >/dev/null 2>&1
    apt install -y curl jq >/dev/null 2>&1

    # Load credentials if they already exist to avoid asking again
    if [ -f "$ENV_FILE" ]; then
        log_info "Loading existing credentials from $ENV_FILE..."
        # Extract values avoiding formatting issues
        BOT_TOKEN=$(grep -E "^BOT_TOKEN=" "$ENV_FILE" | cut -d'=' -f2-)
        ADMIN_ID=$(grep -E "^SUPER_ADMIN=" "$ENV_FILE" | cut -d'=' -f2-)
    fi

    if [ -z "${BOT_TOKEN:-}" ] || [ -z "${ADMIN_ID:-}" ]; then
        read -p "Enter the TOKEN: " BOT_TOKEN
        read -p "Enter your Telegram Chat ID: " ADMIN_ID
    fi

    if [ -z "$BOT_TOKEN" ] || [ -z "$ADMIN_ID" ]; then
        log_error "Error: Incomplete data."
        exit 1
    fi

    # 1. Prepare Environment
    mkdir -p "$PROJECT_DIR"
    echo "BOT_TOKEN=$BOT_TOKEN" > "$ENV_FILE"
    echo "SUPER_ADMIN=$ADMIN_ID" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"

    log_info "Installing base dependencies..."
    apt update -y && apt install -y curl git make wget jq

    # 2. Install Go if it does not exist
    export PATH=$PATH:/usr/local/go/bin
    if ! command -v go &> /dev/null; then
        log_info "Installing GoLang..."
        wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
        rm go1.21.0.linux-amd64.tar.gz
    fi

    # 3. Clone and Compile Project Repo
    log_info "Downloading and compiling the Bot in Go..."
    cd /tmp
    rm -rf privanox-code
    git clone https://github.com/kevinaldaircama/privanox-code.git || { log_error "Error downloading the bot."; exit 1; }
    cd privanox-code

    log_info "Downloading required modules..."
    go mod tidy

    go build -o /usr/local/bin/depwise-bot cmd/depwise/main.go
    chmod +x /usr/local/bin/depwise-bot
    rm -rf /tmp/privanox-code
    cd ~

    # 3.5 Compile BadVPN natively (Ensures compatibility with ARM64/AMD64)
    if [ ! -f "/usr/bin/badvpn-udpgw" ]; then
        log_info "Compiling BadVPN engine (may take 1 minute)..."
        apt install -y cmake build-essential
        cd /tmp
        rm -rf badvpn
        git clone https://github.com/ambrop72/badvpn.git
        cd badvpn
        cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 .
        make
        cp udpgw/badvpn-udpgw /usr/bin/badvpn-udpgw
        chmod +x /usr/bin/badvpn-udpgw
        cd ~
        rm -rf /tmp/badvpn
    fi

    # The Scanner tools (assetfinder/httpx) are installed from
    # the bot's Protocols menu. Not installed here to avoid blocking.

    # 4. Systemd Service
    log_info "Generating SystemD daemon..."
    cat << EOF > /etc/systemd/system/depwise.service
[Unit]
Description=Depwise Telegram Bot (Go Edition)
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=$ENV_FILE
Environment="GOMEMLIMIT=40MiB" "GOGC=20"
ExecStart=/usr/local/bin/depwise-bot
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable depwise.service
    systemctl restart depwise.service
    echo -e "${GREEN}=================================================="
    echo -e "       INSTALLATION V8.0 COMPLETED 💎"
    echo -e "=================================================="
    echo -e "The Go bot is listening. You can send /start on Telegram.${NC}"
}

uninstall_all() {
    echo -e "${RED}=================================================="
    echo -e "       ⚠️ WARNING: FULL UNINSTALL ⚠️"
    echo -e "==================================================${NC}"
    echo -e "This will remove:"
    echo -e "- The Telegram Bot and its configuration"
    echo -e "- All VPN services installed by the bot (SlowDNS, ProxyDT, SSL, etc.)"
    echo -e "- The downloaded binaries"
    echo -e "- The user database (bot_data.json)"

    read -p "Are you completely sure to continue? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Uninstall cancelled."
        return
    fi

    log_info "1/4 Stopping services..."
    systemctl stop depwise.service 2>/dev/null || true
    systemctl disable depwise.service 2>/dev/null || true

    # Stop proxies and vpns
    local services=("badvpn" "proxydt" "stunnel4" "dropbear" "falconproxy" "udpcustom" "zivpn" "nsd")
    for svc in "${services[@]}"; do
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
        rm -f "/etc/systemd/system/${svc}.service"
    done

    log_info "2/4 Removing files and binaries..."
    rm -f /usr/local/bin/depwise-bot
    rm -f /etc/systemd/system/depwise.service
    rm -rf "$PROJECT_DIR"
    rm -f /root/bot_data.json

    # VPN Binaries & Configs
    rm -f /usr/local/bin/badvpn-udpgw
    rm -f /usr/bin/badvpn-udpgw
    rm -f /usr/bin/badvpn
    rm -f /usr/local/bin/proxydt
    rm -f /usr/local/bin/falconproxy
    rm -f /usr/local/bin/udpcustom
    rm -rf /etc/zivpn
    rm -f /usr/local/bin/zivpn
    rm -f /etc/falconproxy.conf
    rm -rf /etc/slowdns

    log_info "3/4 Cleaning GoLang..."
    rm -rf /usr/local/go
    # Remove from PATH if present in bashrc (optional/precaution)
    sed -i '/\/usr\/local\/go\/bin/d' /root/.bashrc || true

    log_info "4/4 Reloading system daemons..."
    systemctl daemon-reload

    echo -e "${GREEN}=================================================="
    echo -e "   ✅ UNINSTALL COMPLETED SUCCESSFULLY  "
    echo -e "==================================================${NC}"
}

enable_root() {
    echo -e "${CYAN}=================================================="
    echo -e "       ENABLING ROOT SSH ACCESS"
    echo -e "==================================================${NC}"
    read -p "Enter a new password for the root user: " ROOT_PASS
    if [ -z "$ROOT_PASS" ]; then
        log_error "The password cannot be empty."
        sleep 2
        return
    fi
    echo "root:$ROOT_PASS" | chpasswd

    # Enable PermitRootLogin
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    if ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi

    # Enable PasswordAuthentication
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    if ! grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    fi

    # Fix AWS override files (Ubuntu 22.04+)
    if [ -d "/etc/ssh/sshd_config.d" ]; then
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
    fi

    # Restart SSH service (supported on Ubuntu 22.04 and 24.04)
    log_info "Restarting SSH service..."
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

    log_info "Root access enabled successfully with password."
    sleep 2
}


show_menu() {
    clear
    echo -e "${CYAN}=================================================="
    echo -e "       DEPWISE BOT INSTALLER (GO EDITION)"
    echo -e "==================================================${NC}"
    echo -e "  1. ${GREEN}Install / Update Bot${NC}"
    echo -e "  2. ${RED}Uninstall Everything (Bot + VPNs)${NC}"
    echo -e "  3. ${YELLOW}Enable Root SSH Access (AWS/VPS)${NC}"
    echo -e "  4. Exit"
    echo -e "${CYAN}==================================================${NC}"
    read -p "Select an option [1-4]: " opt

    case $opt in
        1) install_bot ;;
        2) uninstall_all ;;
        3) enable_root ; show_menu ;;
        4) exit 0 ;;
        *) log_error "Invalid option"; sleep 2; show_menu ;;
    esac
}

show_menu
