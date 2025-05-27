# 🐧 Własny obraz Live Debian + Custom Installer – Cz.4.2: Zaawansowany interaktywny shell startowy

W tej części pokażemy, jak zastąpić klasyczny prompt na tty1 własnym, rozbudowanym interfejsem konsolowym z bannerem ASCII, dynamicznymi informacjami o systemie i zaawansowanym menu. Użytkownik po starcie systemu widzi tylko twoje menu (kiosk mode) – do powłoki przechodzi przez opcję „Login”.

---

## 📋 Spis treści

1. [Wymagania](#1-wymagania)
2. [Konfiguracja projektu](#2-konfiguracja-projektu)
3. [Dodanie obsługi polskich znaków](#3-dodanie-obsługi-polskich-znaków)
4. [Tworzenie zaawansowanego shell-menu](#4-tworzenie-zaawansowanego-shell-menu)
5. [Konfiguracja automatycznego uruchamiania na tty1](#5-konfiguracja-automatycznego-uruchamiania-na-tty1)
6. [Personalizacja systemu](#6-personalizacja-systemu)
7. [Budowanie obrazu ISO](#7-budowanie-obrazu-iso)
8. [Efekt końcowy](#8-efekt-koncowy)
9. [Struktura katalogów](#9-struktura-katalogow)
10. [Przydatne linki](#10-przydatne-linki)
11. [Autor i licencja](#11-autor-i-licencja)

---

> ⚠️❗**Uwaga!**  
> To rozwiązanie zastępuje klasyczne logowanie na tty1 własnym menu. Użytkownik po starcie systemu widzi tylko twoje menu, a nie prompt bash.

> 🔒 **Bezpieczeństwo:**  
> Rozwiązanie 4.2 (kiosk mode) jest bardziej bezpieczne niż 4.1 dla ochrony kodu źródłowego WebUI przed klientami, ponieważ użytkownik nie ma bezpośredniego dostępu do powłoki bez przejścia przez menu.

---

## 🔄 Różnice między Part 4.1 a Part 4.2

| Aspekt | Part 4.1 (Banner po logowaniu) | Part 4.2 (Kiosk mode) |
|--------|--------------------------------|------------------------|
| **Punkt aktywacji** | Po zalogowaniu użytkownika | Zamiast getty@tty1 |
| **Dostęp do powłoki** | Bezpośredni (auto-login) | Przez opcję menu "Login" |
| **Bezpieczeństwo** | Niższe - łatwy dostęp do bash | Wyższe - kontrolowany dostęp |
| **Wygląd** | Banner + zwykły prompt | Pełny interfejs kiosk |
| **Użycie** | Systemy deweloperskie | Systemy produkcyjne/klienckie |

---

## 🔄 Przejście z Part 4.1 do Part 4.2

Jeśli masz już skonfigurowane rozwiązanie z Part 4.1, wykonaj następujące kroki:

### Pliki do usunięcia (z Part 4.1):
```bash
rm -f config/includes.chroot/etc/systemd/system/startup-banner.service
rm -f config/hooks/normal/enable-startup-banner.chroot
```

### Pliki do dodania (Part 4.2):
- `config/includes.chroot/usr/local/bin/mojdebian-shell.sh`
- `config/includes.chroot/etc/systemd/system/mojdebian-console.service`
- `config/hooks/normal/enable-mojdebian-console.chroot`

### Pliki zachowane (bez zmian):
- `config/includes.chroot/usr/local/bin/startup-banner.sh`
- `config/includes.chroot/usr/local/bin/update-issue.sh`
- `config/includes.chroot/etc/systemd/system/update-issue.service`
- `config/hooks/normal/enable-update-issue.chroot`
- Wszystkie inne pliki z poprzednich części

---

## 1. Wymagania

- System: Debian 12 (Bookworm)
- Uprawnienia sudo
- Połączenie z internetem
- około 7GB wolnego miejsca na dysku
- Zakończona konfiguracja z części 2 (wersja konsolowa)

---

## 2. Konfiguracja projektu

> ⚠️ **KRYTYCZNE OSTRZEŻENIE O UPRAWNIENIACH PLIKÓW!**  
> Po sklonowaniu repozytorium z GitHub wszystkie pliki wykonywalne tracą uprawnienia `+x`.  
> **MUSISZ** uruchomić poniższe polecenia przed `lb build`:
> 
> ```bash
> chmod +x config/includes.chroot/usr/local/bin/mojdebian-shell.sh
> chmod +x config/includes.chroot/usr/local/bin/startup-banner.sh
> chmod +x config/includes.chroot/usr/local/bin/update-issue.sh
> chmod +x config/hooks/normal/*.chroot
> ```

Rozpocznij od oczyszczenia poprzedniego build i konfiguracji:

```bash
cd moj-debian
lb clean
sudo lb config -d bookworm --debian-installer live --archive-areas "main contrib non-free non-free-firmware" --debootstrap-options "--variant=minbase"
```

---

## 3. Dodanie obsługi polskich znaków

Zobacz sekcję 3 w README-part4.1.md – konfiguracja pakietów i hooka configure-locale.chroot pozostaje identyczna.

---

## 4. Tworzenie zaawansowanego shell-menu

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
```

### 4.2. Wymagane pakiety dla funkcji menu

Aby wszystkie funkcje menu działały poprawnie, upewnij się, że masz odpowiednie pakiety w `config/package-lists/utils.list.chroot`:

```
lynx
network-manager
console-setup
locales
systemd
```

Nadaj uprawnienia:

```bash
chmod +x config/includes.chroot/usr/local/bin/mojdebian-shell.sh
```

---

## 5. Konfiguracja automatycznego uruchamiania na tty1

### 5.1. Usługa systemd

Utwórz plik:

```bash
nano config/includes.chroot/etc/systemd/system/mojdebian-console.service
```

Wklej:

```
[Unit]
Description=MojDebian Console Interface
After=multi-user.target mywebui.service
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mojdebian-shell.sh
Restart=always
RestartSec=1
StandardInput=tty-force
StandardOutput=tty
TTYPath=/dev/tty1
User=root
Environment=TERM=linux

[Install]
WantedBy=multi-user.target
```

### 5.2. Hook aktywujący usługę

```bash
nano config/hooks/normal/enable-mojdebian-console.chroot
```

Wklej:

```bash
#!/bin/sh
chmod +x /usr/local/bin/mojdebian-shell.sh
systemctl enable mojdebian-console.service
systemctl disable getty@tty1.service
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/enable-mojdebian-console.chroot
```

---

## 6. Personalizacja systemu

Sekcje 6.1–6.3 są identyczne jak w README-part4.1.md (os-release, issue, update-issue.sh, update-issue.service, enable-update-issue.chroot).

---

## 7. Budowanie obrazu ISO

Aby zbudować własny obraz ISO Debiana z przygotowaną konfiguracją, uruchom poniższe polecenie w katalogu projektu:

```bash
sudo lb build
```

---

## 8. Efekt końcowy

Po uruchomieniu systemu:

1. **Na tty1 automatycznie uruchamia się twoje menu** – użytkownik nie widzi klasycznego promptu logowania.
2. **Menu jest rozbudowane, kolorowe, z dynamicznymi informacjami o systemie, statusami usług, logami, itp.**
3. **Przejście do powłoki bash** możliwe tylko przez opcję „Login” w menu.
4. **Wygląd przypomina kiosk/terminal** – użytkownik korzysta tylko z twojego interfejsu.

---

## 9. Struktura katalogów

```
moj-debian-part4.2/
├── config/
│   ├── includes.chroot/
│   │   ├── usr/
│   │   │   └── local/
│   │   │       └── bin/
│   │   │           ├── mojdebian-shell.sh
│   │   │           ├── startup-banner.sh
│   │   │           └── update-issue.sh
│   │   ├── etc/
│   │   │   ├── systemd/
│   │   │   │   └── system/
│   │   │   │       ├── mojdebian-console.service
│   │   │   │       ├── startup-banner.service
│   │   │   │       └── update-issue.service
│   │   │   ├── os-release
│   │   │   └── issue
│   │   └── opt/
│   │       └── mywebui/
│   │           ├── app.py
│   │           └── requirements.txt
│   │ 
│   ├── package-lists/
│   │   ├── base.list.chroot
│   │   ├── utils.list.chroot
│   │   └── python.list.chroot
│   │ 
│   └── hooks/
│       └── normal/
│           ├── configure-locale.chroot
│           ├── install-webui.chroot
│           ├── enable-mywebui.chroot
│           ├── enable-startup-banner.chroot
│           ├── enable-update-issue.chroot
│           └── enable-mojdebian-console.chroot
```

---

## 10. Przydatne linki

- [systemd.service – dokumentacja](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [TTY i getty w systemd](https://wiki.archlinux.org/title/Getty)
- [Bash scripting – kolorowanie tekstu](https://misc.flogisoft.com/bash/tip_colors_and_formatting)
- [live-build lb_config – dokumentacja](https://manpages.debian.org/unstable/live-build/lb_config.1.en.html)
- [Oficjalna dokumentacja Debian Live Systems](https://wiki.debian.org/DebianLive)

---

## 11. Autor i licencja

- Autor: [Sebastian Bartel](https://github.com/SebastianSebastianB)
- E-mail: umbraos@icloud.com
- Licencja: MIT

---
