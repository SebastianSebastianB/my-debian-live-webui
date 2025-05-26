#!/bin/bash
# -*- coding: utf-8 -*-
# Ustawienie kodowania UTF-8 dla polskich znaków
export LANG=pl_PL.UTF-8
export LC_ALL=pl_PL.UTF-8

# Funkcja wyświetlania bannera
show_banner() {
    clear
    # Pobierz aktualny adres IP
    IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+' || echo "brak połączenia")
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
    echo -e "\e[1;34m"
    echo "╔════════════════════════════════════╗"
    echo "║               MENU                 ║"
    echo "╠════════════════════════════════════╣"
    echo "║  1) Ustawienia                     ║"
    echo "║  2) Logowanie                      ║"
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
                ;;
            2)
                echo -e "\e[32mPrzechodzenie do logowania...\e[0m"
                break
                ;;
            3)
                echo -e "\e[31mZamykanie systemu...\e[0m"
                sudo shutdown -h now
                ;;
            4)
                echo -e "\e[33m=== INFORMACJE O SYSTEMIE ===\e[0m"
                echo "Hostname: $(hostname)"
                if command -v uptime >/dev/null 2>&1; then
                    echo "Czas działania: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f3-)"
                else
                    echo "Czas działania: $(cat /proc/uptime | cut -d' ' -f1 | awk '{printf \"%.0f sekund\", $1}')"
                fi
                if command -v free >/dev/null 2>&1; then
                    echo "Użycie pamięci: $(free -h | grep Mem | awk '{print $3"/"$2}' 2>/dev/null || echo 'Niedostępne')"
                else
                    echo "Użycie pamięci: $(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; printf \"%.1fMB/%.1fMB\", used/1024, total/1024}' /proc/meminfo)"
                fi
                if command -v df >/dev/null 2>&1; then
                    echo "Użycie dysku: $(df -h / 2>/dev/null | tail -1 | awk '{print $3"/"$2" ("$5")"}' || echo 'Niedostępne')"
                else
                    echo "Użycie dysku: Niedostępne"
                fi
                if command -v systemctl >/dev/null 2>&1; then
                    echo "Aktywne usługi: $(systemctl list-units --type=service --state=running 2>/dev/null | wc -l || echo 'Niedostępne')"
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
