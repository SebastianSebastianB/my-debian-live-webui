# 🐧 Własny obraz Live Debian + Custom Installer – Cz.4.1: Prosty banner startowy z dynamicznym menu

W tej części pokażemy, jak dodać do systemu konsolowego automatyczne wyświetlanie spersonalizowanego bannera ASCII z logo "MojDebian", informacjami o systemie oraz interaktywne menu po starcie systemu.  
Banner wyświetla dynamicznie odczytywany adres IP WebUI oraz oferuje podstawowe opcje systemowe.

---

## 📋 Spis treści

1. [Wymagania](#1-wymagania)
2. [Konfiguracja projektu](#2-konfiguracja-projektu)
3. [Tworzenie bannera z menu](#3-tworzenie-bannera-z-menu)
4. [Konfiguracja automatycznego uruchamiania](#4-konfiguracja-automatycznego-uruchamiania)
5. [Personalizacja systemu](#5-personalizacja-systemu)
6. [Budowanie obrazu ISO](#6-budowanie-obrazu-iso)
7. [Struktura katalogów](#7-struktura-katalogów)
8. [Przydatne linki](#8-przydatne-linki)
9. [Autor i licencja](#9-autor-i-licencja)

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

## 3. Tworzenie bannera z menu

### 3.1. Skrypt wyświetlający banner

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

# Funkcja wyświetlania bannera
show_banner() {
    clear
    
    # Pobierz aktualny adres IP
    IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "brak połączenia")
    
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
    echo "║  2) Login                          ║"
    echo "║  3) Exit                           ║"
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
                echo "Czas działania: $(uptime -p)"
                echo "Użycie pamięci: $(free -h | grep Mem | awk '{print $3"/"$2}')"
                echo "Użycie dysku: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
                echo "Aktywne usługi: $(systemctl list-units --type=service --state=running | wc -l)"
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

### 3.2. Nadanie uprawnień

```bash
chmod +x config/includes.chroot/usr/local/bin/startup-banner.sh
```

---

## 4. Konfiguracja automatycznego uruchamiania

### 4.1. Usługa systemd

Utwórz usługę, która będzie uruchamiała banner przy starcie:

```bash
nano config/includes.chroot/etc/systemd/system/startup-banner.service
```

Wklej:

```
[Unit]
Description=Startup Banner with Menu
After=network.target mywebui.service
Wants=network.target

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

### 4.2. Hook aktywujący usługę

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

## 5. Personalizacja systemu

### 5.1. Konfiguracja informacji o systemie

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

### 5.2. Banner konsoli (plik issue)

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

### 5.3. Dynamiczne aktualizowanie adresu IP w issue

Aby automatycznie aktualizować adres IP w bannerze, utwórz skrypt:

```bash
nano config/includes.chroot/usr/local/bin/update-issue.sh
```

Wklej:

```bash
#!/bin/bash
# Skrypt aktualizujący /etc/issue z aktualnym IP

# Pobierz adres IP
IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' 2>/dev/null || echo "brak IP")

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

### 5.4. Usługa aktualizująca IP

```bash
nano config/includes.chroot/etc/systemd/system/update-issue.service
```

Wklej:

```
[Unit]
Description=Update issue with current IP
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-issue.sh

[Install]
WantedBy=multi-user.target
```

### 5.5. Hook aktywujący aktualizację IP

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

## 6. Budowanie obrazu ISO

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

### Efekt końcowy

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

## 7. Struktura katalogów

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
│   │   └── python.list.chroot
│   │ 
│   └── hooks/
│       └── normal/
│           ├── install-webui.chroot
│           ├── enable-mywebui.chroot
│           ├── enable-startup-banner.chroot
│           └── enable-update-issue.chroot
```

---

## 8. Przydatne linki

- [systemd.service – dokumentacja](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [TTY i getty w systemd](https://wiki.archlinux.org/title/Getty)
- [Bash scripting – kolorowanie tekstu](https://misc.flogisoft.com/bash/tip_colors_and_formatting)
- [live-build lb_config – dokumentacja konfiguracji](https://manpages.debian.org/unstable/live-build/lb_config.1.en.html)
- [Oficjalna dokumentacja Debian Live Systems](https://wiki.debian.org/DebianLive)

---

## 9. Autor i licencja

- Autor: [Sebastian Bartel](https://github.com/SebastianSebastianB)
- E-mail: umbraos@icloud.com
- Licencja: MIT

---
