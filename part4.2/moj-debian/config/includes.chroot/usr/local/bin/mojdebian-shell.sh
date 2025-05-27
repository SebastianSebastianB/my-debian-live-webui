#!/bin/bash
# Zaawansowany interaktywny shell startowy dla MojDebian

# Kolory
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Funkcja pobierania IP
get_ip() {
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7}')
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$ip" ]; then
        ip="brak połączenia"
    fi
    echo "$ip"
}

# Funkcja wyświetlania bannera
show_banner() {
    clear
    IP=$(get_ip)
    echo -e "$CYAN"
    cat << "EOF"
███╗   ███╗ ██████╗      ██╗██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗     ██║██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║
██╔████╔██║██║   ██║     ██║██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██   ██║██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
    echo -e "$NC"
    echo -e "$YELLOW Wersja: 1.0 - Twoja spersonalizowana dystrybucja Debian $NC"
    echo -e "$GREEN WebUI dostępne pod adresem: http://${IP}:8080 $NC"
    echo ""
    echo -e "$BLUE Hostname: $(hostname) | Kernel: $(uname -r) | Arch: $(uname -m) $NC"
    echo -e "$BLUE Data: $(date '+%Y-%m-%d %H:%M:%S') $NC"
    echo ""
}

main_loop() {    while true; do
        show_banner
        echo -e "$CYAN Wybierz opcję (1-8): $NC"
        echo -e "\e[1;34m" # Bold niebieski    
        echo "╔════════════════════════════════════╗"
        echo "║               MENU                 ║"
        echo "╠════════════════════════════════════╣"    
        echo "║  1) Ustawienia systemu             ║"
        echo "║  2) Login (powłoka)                ║"
        echo "║  3) Restart systemu                ║"
        echo "║  4) Wyłącz system                  ║"
        echo "║  5) Informacje o systemie          ║"
        echo "║  6) Otwórz WebUI (lynx)            ║"
        echo "║  7) Logi systemu                   ║"
        echo "║  8) Powrót do menu                 ║"
        echo "╚════════════════════════════════════╝"
        echo -e "\e[0m"
        read choice
        case $choice in
            1) # Ustawienia systemu
                clear
                echo -e "$YELLOW ═══ USTAWIENIA SYSTEMU ═══ $NC"
                echo "1) Zmień hasło użytkownika"
                echo "2) Konfiguracja sieci"
                echo "3) Timezone/Strefa czasowa"
                echo "4) Powrót do menu głównego"
                read -p "Wybierz opcję: " sys_choice
                case $sys_choice in
                    1) # Zmiana hasła użytkownika
                        passwd
                        ;;
                    2) # Konfiguracja sieci
                        nmtui
                        ;;
                    3) # Timezone/Strefa czasowa
                        dpkg-reconfigure tzdata
                        ;;
                    4) # Powrót do menu głównego
                        continue
                        ;;
                esac
                read -p "Naciśnij ENTER aby kontynuować..."
                ;;
            2) # Login (przejście do powłoki)
                clear
                echo -e "$GREEN Witamy w powłoce bash! Wpisz 'exit' aby wrócić do menu. $NC"
                bash
                ;;
            3) # Restart systemu
                clear
                echo -e "$YELLOW Czy na pewno chcesz zrestartować system? (t/N): $NC"
                read confirm
                if [[ $confirm == "t" || $confirm == "T" ]]; then
                    sudo reboot
                fi
                ;;
            4) # Wyłącz system
                clear
                echo -e "$YELLOW Czy na pewno chcesz wyłączyć system? (t/N): $NC"
                read confirm
                if [[ $confirm == "t" || $confirm == "T" ]]; then
                    sudo shutdown -h now
                fi
                ;;
            5) # Szczegółowe informacje o systemie
                clear
                echo -e "$YELLOW ═══ INFORMACJE O SYSTEMIE ═══ $NC"
                echo -e "$CYAN Hostname: $NC$(hostname)"
                echo -e "$CYAN Kernel: $NC$(uname -r)"
                echo -e "$CYAN Architektura: $NC$(uname -m)"
                echo -e "$CYAN System: $NC$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')"
                echo -e "$CYAN Uptime: $NC$(uptime -p)"
                echo -e "$CYAN Użycie RAM: $NC$(free -h | awk '/^Mem:/ {print $3"/"$2}')"
                echo -e "$CYAN Użycie dysku: $NC$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
                echo -e "$CYAN IP adres: $NC$(get_ip)"
                echo -e "$CYAN Data: $NC$(date '+%Y-%m-%d %H:%M:%S')"
                read -p "Naciśnij ENTER aby kontynuować..."
                ;;
            6) # Otwórz WebUI w lynx
                clear
                IP=$(get_ip)
                if [[ "$IP" != "brak połączenia" ]]; then
                    echo -e "$GREEN Otwieranie WebUI w przeglądarce tekstowej lynx... $NC"
                    echo -e "$YELLOW Naciśnij 'q' aby zamknąć lynx i wrócić do menu $NC"
                    sleep 2
                    lynx "http://${IP}:8080" 2>/dev/null || echo "Błąd: lynx nie jest zainstalowany lub WebUI nie jest dostępne"
                else
                    echo -e "$YELLOW Brak połączenia sieciowego - WebUI niedostępne $NC"
                    read -p "Naciśnij ENTER aby kontynuować..."
                fi
                ;;
            7) # Logi systemu
                clear
                echo -e "$YELLOW ═══ LOGI SYSTEMU ═══ $NC"
                echo "1) Ostatnie logi systemowe (journalctl)"
                echo "2) Logi serwisu WebUI"
                echo "3) Logi boot"
                echo "4) Powrót do menu głównego"
                read -p "Wybierz opcję: " log_choice
                case $log_choice in
                    1) # Ostatnie logi systemowe
                        journalctl -n 50 --no-pager
                        ;;
                    2) # Logi serwisu WebUI
                        journalctl -u mywebui.service -n 20 --no-pager
                        ;;
                    3) # Logi boot
                        journalctl -b --no-pager
                        ;;
                    4) # Powrót do menu głównego
                        continue
                        ;;
                esac
                read -p "Naciśnij ENTER aby kontynuować..."
                ;;
            8) # Wyjście z menu
                break
                ;;
            *) # Nieprawidłowa opcja
                echo "Nieprawidłowa opcja!"
                ;;
        esac
    done
}

main_loop
