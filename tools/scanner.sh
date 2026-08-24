#!/bin/bash

# Colors for the menu
GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Custom banner
mostrar_banner() {
    clear
    echo -e "${BLUE}======================================================${RESET}"
    echo -e "${GREEN}      ORX Tunnel Scanner - Subdomains and CDN/WAF        ${RESET}"
    echo -e "${YELLOW}            By ORX Tunnel tutorials                  ${RESET}"
    echo -e "${BLUE}======================================================${RESET}"
    echo ""
}

# Function 0: Check and install dependencies
verificar_dependencias() {
    echo -e "${YELLOW}[*] Checking required dependencies...${RESET}"

    # Check Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}[!] Go is not installed. Starting installation...${RESET}"
        sudo apt update && sudo apt install golang-go -y
    else
        echo -e "${GREEN}[+] Go detected.${RESET}"
    fi

    # Check Assetfinder
    if ! command -v assetfinder &> /dev/null; then
        echo -e "${RED}[!] Assetfinder is not installed. Starting installation...${RESET}"
        go install github.com/tomnomnom/assetfinder@latest
        sudo cp ~/go/bin/assetfinder /usr/local/bin/ 2>/dev/null
    else
        echo -e "${GREEN}[+] Assetfinder detected.${RESET}"
    fi

    # Check httpx
    if ! command -v httpx &> /dev/null; then
        echo -e "${RED}[!] httpx is not installed. Starting installation...${RESET}"
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        sudo cp ~/go/bin/httpx /usr/local/bin/ 2>/dev/null
    else
        echo -e "${GREEN}[+] httpx detected.${RESET}"
    fi

    echo -e "${GREEN}[+] Environment ready to work.${RESET}"
    sleep 2
}

# Function 1: Search Subdomains
buscar_subdominios() {
    read -p "Enter the target domain (e.g. domain.com): " dominio
    echo -e "${YELLOW}[*] Searching subdomains with Assetfinder...${RESET}"

    assetfinder --subs-only $dominio | sort -u > "subdominios_$dominio.txt"
    total=$(wc -l < "subdominios_$dominio.txt")

    echo -e "${GREEN}[+] Search completed. $total subdomains found.${RESET}"
    echo -e "${GREEN}[+] Saved to: subdominios_$dominio.txt${RESET}"
    echo ""
    read -p "Press Enter to continue..."
}

# Function 2: Detect Technologies and CDN
detectar_tecnologias() {
    read -p "Enter the name of the file with the subdomain list: " archivo

    if [ ! -f "$archivo" ]; then
        echo -e "${RED}[!] The file $archivo does not exist.${RESET}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${YELLOW}[*] Analyzing services (Cloudflare, CloudFront, etc.) with httpx...${RESET}"
    cat "$archivo" | httpx -silent -status-code -ip -tech-detect -title | tee "resultados_tech_$archivo"

    echo ""
    echo -e "${GREEN}[+] Analysis completed. Results in: resultados_tech_$archivo${RESET}"
    read -p "Press Enter to continue..."
}

# Function 3: Full Scan
escaneo_completo() {
    read -p "Enter the target domain (e.g. domain.com): " dominio
    echo -e "${YELLOW}[*] Step 1: Searching subdomains...${RESET}"
    assetfinder --subs-only $dominio | sort -u > "subdominios_$dominio.txt"

    total=$(wc -l < "subdominios_$dominio.txt")
    echo -e "${GREEN}[+] $total subdomains found.${RESET}"

    echo -e "${YELLOW}[*] Step 2: Analyzing technologies and detecting CDN/WAF...${RESET}"
    cat "subdominios_$dominio.txt" | httpx -silent -status-code -ip -tech-detect -title | tee "escaneo_completo_$dominio.txt"

    echo -e "${GREEN}[+] Process finished. Results saved in: escaneo_completo_$dominio.txt${RESET}"
    read -p "Press Enter to continue..."
}

# Run check on startup
verificar_dependencias

# Main Menu
while true; do
    mostrar_banner
    echo -e "Select an option:"
    echo -e "  ${GREEN}1)${RESET} Search subdomains only (Assetfinder)"
    echo -e "  ${GREEN}2)${RESET} Detect CDN/WAF from an existing list (httpx)"
    echo -e "  ${GREEN}3)${RESET} Full Automatic Scan (Recommended)"
    echo -e "  ${RED}4)${RESET} Exit"
    echo ""
    read -p "Option: " opcion

    case $opcion in
        1) buscar_subdominios ;;
        2) detectar_tecnologias ;;
        3) escaneo_completo ;;
        4) echo -e "${YELLOW}Goodbye!${RESET}"; exit 0 ;;
        *) echo -e "${RED}[!] Invalid option.${RESET}"; sleep 1 ;;
    esac
done
