#!/bin/bash
# -*- coding: utf-8 -*-
# Ustawienie kodowania UTF-8 dla polskich znaków
export LANG=pl_PL.UTF-8
export LC_ALL=pl_PL.UTF-8

# Funkcja pobierania IP z retry
get_ip_with_retry() {
    local max_attempts=10
    local delay=2
    local ip=""
    
    for i in $(seq 1 $max_attempts); do
        ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7}' 2>/dev/null)
        if [ -z "$ip" ]; then
            ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null)
        fi
        if [ -z "$ip" ]; then
            ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        fi
        
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
        
        # Wyświetl informację o próbie tylko przy pierwszym uruchomieniu
        if [ $i -eq 1 ]; then
            echo "Oczekiwanie na konfigurację sieci..." >&2
        fi
        
        sleep $delay
    done
    
    echo "brak połączenia"
}

# Funkcja wyświetlania bannera
show_banner() {
    clear
    
    # Pobierz aktualny adres IP z retry
    IP=$(get_ip_with_retry)
    
    # Wyświetl banner
    echo -e "\e[36m"  # Kolor cyan
    cat << "EOF"
███╗   ███╗ ██████╗      ██╗██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗     ██║██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║
██╔████╔██║██║   ██║     ██║██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██   ██║██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
    echo -e "\e[0m"  # Reset koloru
    
    echo -e "\e[33mWersja: 1.0 - Twoja spersonalizowana dystrybucja Debian\e[0m"
    echo -e "\e[32mWebUI dostępne pod adresem: http://${IP}:8080\e[0m"
    echo ""
    echo -e "\e[1;34m" # Bold niebieski    
    echo "╔════════════════════════════════════╗"
    echo "║               MENU                 ║"
    echo "╠════════════════════════════════════╣"    
    echo "║  1) Ustawienia                     ║"
    echo "║  2) Terminal                       ║"
    echo "║  3) Wyjście                        ║"
    echo "║  4) Informacje o systemie          ║"
    echo "║  5) Status usług                   ║"
    echo "╚════════════════════════════════════╝"
    echo -e "\e[0m"
}

# Funkcja obsługi menu
handle_menu() {
    while true; do
        echo -n -e "\e[1;36mWybierz opcję (1-5): \e[0m"
        read choice
        
        case $choice in
            1)
                echo -e "\e[33m=== USTAWIENIA SYSTEMU ===\e[0m"
                echo "1. Zmień hasło użytkownika"
                echo "2. Konfiguracja sieci"
                echo "3. Restart usług"
                echo "4. Powrót do menu głównego"
                echo -n "Wybierz (1-4): "
                read sub_choice
                case $sub_choice in
                    1) passwd ;;
                    2) nmtui ;;
                    3) 
                        echo "Restartowanie usług..."
                        systemctl restart mywebui.service
                        echo "Usługi zostały zrestartowane."
                        ;;
                    4) show_banner; handle_menu; return ;;
                esac
                ;;            2)
                echo -e "\e[32mPrzechodzenie do terminala Debian...\e[0m"
                echo "Uruchamianie powłoki bash. Wpisz 'exit' aby wrócić do menu."
                echo ""
                exec /bin/bash
                ;;            
            3)
                echo -e "\e[31mZamykanie systemu...\e[0m"
                sudo shutdown -h now
                ;;
            4)
                echo -e "\e[33m=== INFORMACJE O SYSTEMIE ===\e[0m"
                echo "Hostname: $(hostname)"                  # Sprawdź dostępność komend systemowych
                if command -v uptime >/dev/null 2>&1; then
                    echo "Czas działania: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f3-)"
                else
                    echo "Czas działania: $(cat /proc/uptime | cut -d' ' -f1 | awk '{printf "%.0f sekund", $1}')"
                fi
                
                # Informacje o pamięci - pełne dane z free
                if command -v free >/dev/null 2>&1; then
                    echo ""
                    echo "=== PAMIĘĆ ==="
                    free -h
                else
                    echo "Pamięć: Niedostępne (brak komendy free)"
                fi
                
                # Informacje o procesorze
                if [ -f /proc/cpuinfo ]; then
                    echo ""
                    echo "=== PROCESOR ==="
                    echo "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')"
                    echo "Rdzenie: $(grep -c '^processor' /proc/cpuinfo)"
                    echo "Architektura: $(uname -m)"
                else
                    echo "Procesor: Niedostępne"
                fi
                
                # Informacje o karcie graficznej
                echo ""
                echo "=== KARTA GRAFICZNA ==="
                if command -v lspci >/dev/null 2>&1; then
                    lspci | grep -i 'vga\|3d\|display' | sed 's/^[0-9:.]* //' || echo "Nie wykryto karty graficznej"
                else
                    echo "Niedostępne (brak komendy lspci)"
                fi
                
                # Użycie dysku
                if command -v df >/dev/null 2>&1; then
                    echo ""
                    echo "=== DYSK ==="
                    echo "Użycie dysku: $(df -h / 2>/dev/null | tail -1 | awk '{print $3"/"$2" ("$5")"}' || echo 'Niedostępne')"
                else
                    echo "Użycie dysku: Niedostępne"
                fi
                
                # Lista aktywnych usług
                if command -v systemctl >/dev/null 2>&1; then
                    echo ""
                    echo "=== AKTYWNE USŁUGI ==="
                    echo "Liczba usług: $(systemctl list-units --type=service --state=running 2>/dev/null | wc -l || echo 'Niedostępne')"
                    echo "Lista głównych usług:"
                    systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -E '\.(service)' | head -10 | awk '{print "  - " $1}' || echo "  Niedostępne"
                else
                    echo "Aktywne usługi: Niedostępne"
                fi
                echo ""
                echo "Naciśnij Enter aby kontynuować..."
                read
                show_banner
                ;;
            5)
                echo -e "\e[33m=== STATUS USŁUG ===\e[0m"
                echo "WebUI Service:"
                systemctl status mywebui.service --no-pager -l
                echo ""
                echo "Network Manager:"
                systemctl status NetworkManager --no-pager -l
                echo ""
                echo "Naciśnij Enter aby kontynuować..."
                read
                show_banner
                ;;
            *)
                echo -e "\e[31mNieprawidłowa opcja! Wybierz 1-5.\e[0m"
                ;;
        esac
    done
}

# Główna funkcja
main() {
    show_banner
    handle_menu
}

# Uruchom tylko jeśli skrypt jest wykonywany bezpośrednio
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
