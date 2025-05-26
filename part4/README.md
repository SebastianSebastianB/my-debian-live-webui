# Part 4: Konfiguracja bannera startowego z dynamicznym menu

Ta konfiguracja tworzy system konsolowy z automatycznym bannerem startowym zawierającym:

## Funkcje:
- **ASCII Art Logo** "MojDebian" 
- **Dynamiczne wykrywanie IP** dla WebUI
- **Interaktywne menu** z 5 opcjami
- **Obsługa polskich znaków** (UTF-8)
- **Automatyczne uruchamianie** przy starcie systemu

## Zawartość:

### Skrypty:
- `startup-banner.sh` - główny skrypt bannera z menu
- `update-issue.sh` - aktualizacja IP w `/etc/issue`

### Usługi systemd:
- `startup-banner.service` - uruchamia banner z menu
- `update-issue.service` - aktualizuje IP w bannerze logowania
- `mywebui.service` - serwis WebUI

### Hook'i instalacyjne:
- `configure-locale.chroot` - konfiguracja polskich locale
- `enable-startup-banner.chroot` - aktywacja bannera
- `enable-update-issue.chroot` - aktywacja aktualizacji IP
- `install-webui.chroot` - instalacja WebUI
- `enable-mywebui.chroot` - aktywacja WebUI

### Pliki systemowe:
- `/etc/os-release` - informacje o dystrybucji
- `/etc/issue` - banner logowania

## Menu opcje:
1. **Ustawienia** - zmiana hasła, konfiguracja sieci, restart usług
2. **Logowanie** - przejście do powłoki bash
3. **Wyjście** - bezpieczne wyłączenie systemu
4. **Informacje o systemie** - uptime, pamięć, dysk, usługi
5. **Status usług** - sprawdzenie WebUI i NetworkManager

## Pakiety systemowe:
Automatycznie instaluje narzędzia systemowe:
- `procps` (free, ps, top, uptime)
- `coreutils` (ls, cat, grep, awk) 
- `util-linux` (mount, df, lsblk)
- `net-tools` (ifconfig, netstat)
- `locales`, `console-setup`, `keyboard-configuration` (polskie znaki)

## Budowanie:
```bash
cd part4/moj-debian
sudo lb build
```

## Efekt:
Po uruchomieniu system automatycznie wyświetla kolorowy banner z logo i menu, umożliwiając łatwe zarządzanie systemem bez znajomości komend Linux.
