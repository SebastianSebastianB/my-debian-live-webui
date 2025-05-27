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

Zobacz sekcję 3 w README-part4.1.md – konfiguracja pakietów i hooka configure-locale.chroot pozostaje identyczna.

---

## 4. Tworzenie zaawansowanego shell-menu

### 4.1. Skrypt interaktywnego menu

Utwórz plik:

```bash
nano config/includes.chroot/usr/local/bin/mojdebian-shell.sh
```

Wklej poniższy przykładowy kod (możesz go rozbudować według własnych potrzeb):

```bash
#!/bin/bash
# Zaawansowany interaktywny shell startowy dla MojDebian

# ...definicje kolorów i funkcji pomocniczych...

main_loop() {
    while true; do
        # ...wyświetlanie bannera, statusów, menu...
        echo -n "Wybierz opcję (1-8): "
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
