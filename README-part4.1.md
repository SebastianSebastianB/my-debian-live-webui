# 🐧 Własny obraz Live Debian + Custom Installer – Cz.4.1: Prosty banner startowy z dynamicznym menu

W tej części pokażemy, jak dodać do systemu konsolowego automatyczne wyświetlanie spersonalizowanego bannera ASCII z logo "MojDebian", informacjami o systemie oraz interaktywne menu po starcie systemu.  
Banner wyświetla dynamicznie odczytywany adres IP WebUI oraz oferuje podstawowe opcje systemowe.

---

## 📋 Spis treści

1. [Wymagania](#1-wymagania)
2. [Konfiguracja projektu](#2-konfiguracja-projektu)
3. [Dodanie obsługi polskich znaków](#3-dodanie-obsługi-polskich-znaków)
4. [Tworzenie bannera z menu](#4-tworzenie-bannera-z-menu)
5. [Konfiguracja automatycznego uruchamiania](#5-konfiguracja-automatycznego-uruchamiania)
6. [Personalizacja systemu](#6-personalizacja-systemu)
7. [Budowanie obrazu ISO](#7-budowanie-obrazu-iso)
8. [Efekt końcowy](#8-efekt-koncowy)
9. [Struktura katalogów](#9-struktura-katalogow)
10. [Przydatne linki](#10-przydatne-linki)
11. [Autor i licencja](#11-autor-i-licencja)

---

> ⚠️❗**Uwaga!**  
> Ta część bazuje na konfiguracji z części 2 (wersja konsolowa). Upewnij się, że usunąłeś pakiety graficzne z `base.list.chroot`:
> ```
> # xfce4                # <- usuń tę linię
> # openbox              # <- usuń tę linię  
> # network-manager      # <- usuń tę linię
> ```

---

## 1. Wymagania

- System: Debian 12 (Bookworm)
- Uprawnienia sudo
- Połączenie z internetem
- około 7GB wolnego miejsca na dysku
- Zakończona konfiguracja z części 2 (wersja konsolowa)

---

## 2. Konfiguracja projektu

Rozpocznij od oczyszczenia poprzedniego build i konfiguracji:

```bash
cd moj-debian
lb clean
sudo lb config -d bookworm --debian-installer live --archive-areas "main contrib non-free non-free-firmware" --debootstrap-options "--variant=minbase"
```

---

## 3. Dodanie obsługi polskich znaków

### 3.1. Pakiety lokalizacji

Dodaj pakiety do dwóch plików list pakietów:

#### config/package-lists/base.list.chroot

```
# Podstawowe narzędzia i pakiety systemowe (konsola)
sudo
ufw
curl
wget
git
ifupdown
wpasupplicant
firmware-iwlwifi
isc-dhcp-client
grub-efi
```

#### config/package-lists/utils.list.chroot

```
# Obsługa polskich znaków i narzędzia systemowe
locales
console-setup
keyboard-configuration
procps
coreutils
util-linux
net-tools
pciutils
```

**Objaśnienie pakietów:**
- `locales` - obsługa języków i kodowań (UTF-8, polskie znaki)
- `console-setup` - konfiguracja konsoli (czcionki, klawiatura)
- `keyboard-configuration` - ustawienia klawiatury (polskie znaki)
- `procps` - narzędzia systemowe (`free`, `ps`, `top`, `uptime`)
- `coreutils` - podstawowe narzędzia GNU (`ls`, `cat`, `grep`, `awk`)
- `util-linux` - narzędzia systemowe (`mount`, `df`, `lsblk`)
- `net-tools` - narzędzia sieciowe (`ifconfig`, `netstat`)
- `pciutils` - narzędzia do wykrywania urządzeń PCI (`lspci`)

### 3.2. Konfiguracja locale

Utwórz hook konfigurujący polskie locale:

```bash
mkdir -p config/hooks/normal/
nano config/hooks/normal/configure-locale.chroot
```

Wklej:

```bash
#!/bin/sh
# Konfiguracja polskich locale

# Generuj locale pl_PL.UTF-8
echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Ustaw domyślne locale
echo "LANG=pl_PL.UTF-8" > /etc/default/locale
echo "LC_ALL=pl_PL.UTF-8" >> /etc/default/locale

# Konfiguracja konsoli dla polskich znaków
echo "CHARMAP=UTF-8" > /etc/default/console-setup
echo "CODESET=guess" >> /etc/default/console-setup
echo "FONTFACE=Fixed" >> /etc/default/console-setup
echo "FONTSIZE=16" >> /etc/default/console-setup

# Konfiguracja klawiatury polskiej
echo "XKBMODEL=pc105" > /etc/default/keyboard
echo "XKBLAYOUT=pl" >> /etc/default/keyboard
echo "XKBVARIANT=" >> /etc/default/keyboard
echo "XKBOPTIONS=" >> /etc/default/keyboard

# Ustaw locale dla bieżącej sesji
export LANG=pl_PL.UTF-8
export LC_ALL=pl_PL.UTF-8
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/configure-locale.chroot
```

---

## 4. Tworzenie bannera z menu

### 4.1. Skrypt wyświetlający banner

Najpierw utwórz folder na skrypt:

```bash
mkdir -p config/includes.chroot/usr/local/bin
```

Następnie utwórz skrypt, który będzie wyświetlał banner z logo i menu:

```bash
nano config/includes.chroot/usr/local/bin/startup-banner.sh
```

Wklej:

```bash
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
                ;;            
            2)
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
```

### 4.2. Nadanie uprawnień

```bash
chmod +x config/includes.chroot/usr/local/bin/startup-banner.sh
```

---

## 5. Konfiguracja automatycznego uruchamiania

### 5.1. Usługa systemd

Utwórz usługę, która będzie uruchamiała banner przy starcie:

```bash
nano config/includes.chroot/etc/systemd/system/startup-banner.service
```

Wklej:

```
[Unit]
Description=Startup Banner with Menu
After=network-online.target mywebui.service
Wants=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/startup-banner.sh
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty1
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
```

### 5.2. Hook aktywujący usługę

```bash
nano config/hooks/normal/enable-startup-banner.chroot
```

Wklej:

```bash
#!/bin/sh
systemctl enable startup-banner.service

# Wyłącz getty na tty1 aby nie kolidowało
systemctl disable getty@tty1.service
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/enable-startup-banner.chroot
```

---

## 6. Personalizacja systemu

### 6.1. Konfiguracja informacji o systemie

```bash
nano config/includes.chroot/etc/os-release
```

Wklej:

```
PRETTY_NAME="MojDebian GNU/Linux"
NAME="MojDebian"
VERSION_ID="1.0"
VERSION="1.0 (Custom)"
ID=mojdebian
ID_LIKE=debian
HOME_URL="https://github.com/SebastianSebastianB/my-debian-live-webui"
SUPPORT_URL="https://github.com/SebastianSebastianB/my-debian-live-webui/issues"
BUG_REPORT_URL="https://github.com/SebastianSebastianB/my-debian-live-webui/issues"
```

### 6.2. Banner konsoli (plik issue)

```bash
nano config/includes.chroot/etc/issue
```

Wklej:

```
MojDebian GNU/Linux \r \l

███╗   ███╗ ██████╗      ██╗██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗     ██║██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║
██╔████╔██║██║   ██║     ██║██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██   ██║██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

Wersja: 1.0 - Twoja spersonalizowana dystrybucja Debian
Dla dostępu do WebUI sprawdź adres IP: ip a

```

---

> 💡 **Wskazówka:**  
> Plik `/etc/issue` wyświetla się podczas logowania w konsoli (TTY) PRZED podaniem nazwy użytkownika i hasła.  
> Zmienne `\r` i `\l` automatycznie wyświetlają wersję jądra i nazwę terminala.

---

### 6.3. Dynamiczne aktualizowanie adresu IP w issue

Aby automatycznie aktualizować adres IP w bannerze, utwórz skrypt:

```bash
nano config/includes.chroot/usr/local/bin/update-issue.sh
```

Wklej:

```bash
#!/bin/bash
# Skrypt aktualizujący /etc/issue z aktualnym IP

# Funkcja pobierania IP z retry
get_ip_with_retry() {
    local max_attempts=5
    local delay=1
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
        
        sleep $delay
    done
    
    echo "brak IP"
}

# Pobierz adres IP z retry
IP=$(get_ip_with_retry)

# Aktualizuj /etc/issue
cat > /etc/issue << EOF
MojDebian GNU/Linux \\r \\l

███╗   ███╗ ██████╗      ██╗██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗     ██║██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║
██╔████╔██║██║   ██║     ██║██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██   ██║██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

Wersja: 1.0 - Twoja spersonalizowana dystrybucja Debian
WebUI dostępne pod adresem: http://${IP}:8080

EOF
```

### 6.4. Usługa aktualizująca IP

```bash
nano config/includes.chroot/etc/systemd/system/update-issue.service
```

Wklej:

```
[Unit]
Description=Update issue with current IP
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-issue.sh

[Install]
WantedBy=multi-user.target
```

### 6.5. Hook aktywujący aktualizację IP

```bash
nano config/hooks/normal/enable-update-issue.chroot
```

Wklej:

```bash
#!/bin/sh
chmod +x /usr/local/bin/update-issue.sh
systemctl enable update-issue.service
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/enable-update-issue.chroot
```

---

## 7. Budowanie obrazu ISO

Aby zbudować własny obraz ISO Debiana z przygotowaną konfiguracją, uruchom poniższe polecenie w katalogu projektu:

```bash
sudo lb build
```

Proces budowania może potrwać od kilku do kilkudziesięciu minut w zależności od wydajności komputera oraz szybkości łącza internetowego.

Po zakończeniu w katalogu projektu pojawi się plik `.iso` (np. `live-image-amd64.hybrid.iso`).  
Ten plik możesz:

- **Uruchomić w maszynie wirtualnej** (np. VirtualBox, QEMU, VMware)
- **Nagrać na pendrive** (np. za pomocą balenaEtcher, Rufus, dd) i uruchomić na fizycznym komputerze
- **Zainstalować system** na dysku lub używać w trybie Live

---

## 8. Efekt końcowy

Po uruchomieniu systemu:

1. **Podczas logowania** - wyświetla się banner z `/etc/issue` z aktualnym IP
2. **Po zalogowaniu** - automatycznie uruchamia się kolorowy banner z interaktywnym menu
3. **Menu oferuje**:
   - Ustawienia systemu (zmiana hasła, konfiguracja sieci, restart usług)
   - Przejście do normalnej powłoki (Login)
   - Wyłączenie systemu (Exit)
   - Informacje o systemie (użycie pamięci, dysku, uptime)
   - Status usług (WebUI, NetworkManager)

---

## 9. Struktura katalogów

```
moj-debian-part4.1/
├── config/
│   ├── includes.chroot/
│   │   ├── usr/
│   │   │   └── local/
│   │   │       └── bin/
│   │   │           ├── startup-banner.sh
│   │   │           └── update-issue.sh
│   │   ├── etc/
│   │   │   ├── systemd/
│   │   │   │   └── system/
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
│           └── enable-update-issue.chroot
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
