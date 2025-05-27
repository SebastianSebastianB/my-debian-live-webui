# ...existing code...

---

> ⚠️❗**WAŻNE! Po pobraniu lub sklonowaniu repozytorium na systemie Linux należy nadać uprawnienia wykonywalności skryptom i hookom.**
> 
> W katalogu projektu uruchom:
> 
> ```bash
> chmod +x config/includes.chroot/usr/local/bin/mojdebian-shell.sh
> chmod +x config/includes.chroot/usr/local/bin/update-issue.sh
> chmod +x config/hooks/normal/configure-locale.chroot
> chmod +x config/hooks/normal/enable-mojdebian-console.chroot
> chmod +x config/hooks/normal/enable-update-issue.chroot
> chmod +x config/hooks/normal/install-webui.chroot
> chmod +x config/hooks/normal/enable-mywebui.chroot
> ```
> 
> Bez tych uprawnień skrypty nie będą działać podczas budowy obrazu ISO!

### 4.1. Skrypt interaktywnego menu

Utwórz plik:

```bash
nano config/includes.chroot/usr/local/bin/mojdebian-shell.sh
```

Wklej poniższy kod przykładowy (możesz go rozbudować według własnych potrzeb):

```bash
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

main_loop() {
    while true; do
        show_banner
        echo -e "$CYAN Wybierz opcję (1-8): $NC"
        read choice
        case $choice in
            1) # Ustawienia systemu
                ;;
            2) # Login (przejście do powłoki)
                bash
                ;;
            3) # Restart systemu
                sudo reboot
                ;;
            4) # Wyłącz system
                sudo shutdown -h now
                ;;
            5) # Szczegółowe informacje o systemie
                ;;
            6) # Otwórz WebUI w lynx
                ;;
            7) # Logi systemu
                ;;
            8) continue ;;
            *) echo "Nieprawidłowa opcja!" ;;
        esac
    done
}

main_loop
```

Nadaj uprawnienia:

```bash
chmod +x config/includes.chroot/usr/local/bin/mojdebian-shell.sh
```

# ...existing code...