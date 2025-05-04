# 🐧 Własny obraz Live Debian + OpenCV GUI – Cz.3: Automatyczne uruchamianie aplikacji OpenCV po starcie systemu

W tej części pokażemy, jak przygotować własny obraz Debiana, który po starcie automatycznie uruchamia aplikację GUI napisaną w Pythonie z wykorzystaniem biblioteki OpenCV.  
Aplikacja otwiera się na pełnym ekranie i posiada przycisk "Exit GUI" zamykający okno.  
Dodatkowo zabezpieczymy folder z aplikacją przed niepowołanym dostępem.

---

## 📋 Spis treści

1. [Wymagania](#1-wymagania)
2. [Konfiguracja projektu](#2-konfiguracja-projektu)
3. [Dodanie pakietów](#3-dodanie-pakietów)
4. [Tworzenie aplikacji OpenCV GUI](#4-tworzenie-aplikacji-opencv-gui)
5. [Konfiguracja systemd](#5-konfiguracja-systemd)
6. [Zabezpieczenie folderu aplikacji](#6-zabezpieczenie-folderu-aplikacji)
7. [Budowanie obrazu ISO](#7-budowanie-obrazu-iso)
8. [Najczęstsze problemy](#8-najczęstsze-problemy)
9. [Struktura katalogów](#9-struktura-katalogów)
10. [Przydatne linki](#10-przydatne-linki)
11. [Autor i licencja](#11-autor-i-licencja)

---

## 1. Wymagania

- System: Debian 12 (Bookworm)
- Uprawnienia sudo
- Połączenie z internetem
- ok. 7GB wolnego miejsca na dysku

---

## 2. Konfiguracja projektu

Stwórz nowy katalog projektu dla tej części:

```bash
sudo mkdir moj-debian
cd moj-debian
```

Wszystkie kolejne polecenia wykonuj w tym katalogu.

---

### Konfiguracja live-build

```bash
lb clean
sudo lb config -d bookworm --debian-installer live --archive-areas "main contrib non-free non-free-firmware" --debootstrap-options "--variant=minbase"
```

---

## 3. Dodanie pakietów

### 3a. Pakiety systemowe

Stwórz plik z listą pakietów systemowych:

```bash
nano config/package-lists/base.list.chroot
```

Wklej:

```
# Podstawowe narzędzia i pakiety systemowe
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

# Środowisko graficzne (XFCE lub minimalne Xorg)
xorg
# xfce4
```

### 3b. Pakiety Python

```bash
nano config/package-lists/python.list.chroot
```

Wklej:

```
python3
python3-pip
python3-venv
```

---

## 4. Tworzenie aplikacji OpenCV GUI

### 4.1. Utwórz folder na aplikację

```bash
mkdir -p config/includes.chroot/opt/myopencvapp
```

### 4.2. Plik aplikacji

```bash
nano config/includes.chroot/opt/myopencvapp/app.py
```

Wklej poniższy kod:

```python
import cv2
import numpy as np
import subprocess

def get_screen_resolution():
    try:
        output = subprocess.check_output("xrandr | grep '*'", shell=True).decode()
        res = output.split()[0]
        width, height = map(int, res.split('x'))
        return width, height
    except Exception:
        return 1024, 768

def main():
    screen_w, screen_h = get_screen_resolution()
    img = np.zeros((screen_h, screen_w, 3), dtype=np.uint8)

    cv2.namedWindow("OpenCV GUI", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("OpenCV GUI", screen_w, screen_h)
    cv2.imshow("OpenCV GUI", img)
    cv2.waitKey(1)
    cv2.setWindowProperty("OpenCV GUI", cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    # Informacja o GUI
    cv2.putText(img, "OpenCV GUI Demo", (int(screen_w*0.2), int(screen_h*0.25)), cv2.FONT_HERSHEY_SIMPLEX, 2, (255,255,255), 3)
    # Informacja o rozdzielczosci
    res_text = f"Resolution: {screen_w}x{screen_h}"
    cv2.putText(img, res_text, (int(screen_w*0.2), int(screen_h*0.25)+60), cv2.FONT_HERSHEY_SIMPLEX, 1, (200,200,0), 2)

    button_color = (40, 180, 40)
    btn_w, btn_h = 200, 100
    btn_x1 = screen_w//2 - btn_w//2
    btn_y1 = screen_h//2 - btn_h//2
    btn_x2 = btn_x1 + btn_w
    btn_y2 = btn_y1 + btn_h
    cv2.rectangle(img, (btn_x1, btn_y1), (btn_x2, btn_y2), button_color, -1)
    cv2.putText(img, "Exit GUI", (btn_x1+20, btn_y1+60), cv2.FONT_HERSHEY_SIMPLEX, 2, (255,255,255), 3)

    def on_mouse(event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            if btn_x1 <= x <= btn_x2 and btn_y1 <= y <= btn_y2:
                cv2.destroyAllWindows()
                exit(0)
    cv2.setMouseCallback("OpenCV GUI", on_mouse)

    while True:
        cv2.imshow("OpenCV GUI", img)
        key = cv2.waitKey(1) & 0xFF
        if key == 27:  # ESC
            break

    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
```

### 4.3. Plik z zależnościami

```bash
nano config/includes.chroot/opt/myopencvapp/requirements.txt
```

Wklej:

```
opencv-python
numpy
```

### 4.4. Hook instalujący zależności w virtualenv

```bash
mkdir -p config/hooks/normal/
nano config/hooks/normal/install-opencvapp.chroot
```

Wklej:

```bash
#!/bin/sh
python3 -m venv /opt/myopencvapp/venv
/opt/myopencvapp/venv/bin/pip install -r /opt/myopencvapp/requirements.txt
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/install-opencvapp.chroot
```

---

## 5. Konfiguracja systemd

### 5.1. Plik usługi

```bash
mkdir -p config/includes.chroot/etc/systemd/system
nano config/includes.chroot/etc/systemd/system/myopencvapp.service
```

Wklej:

```
[Unit]
Description=My OpenCV GUI App

[Service]
ExecStart=/opt/myopencvapp/venv/bin/python /opt/myopencvapp/app.py
WorkingDirectory=/opt/myopencvapp
Restart=always
User=root

[Install]
WantedBy=graphical.target
```

### 5.2. Hook aktywujący usługę

```bash
nano config/hooks/normal/enable-myopencvapp.chroot
```

Wklej:

```bash
#!/bin/sh
systemctl enable myopencvapp.service
```

Nadaj uprawnienia:

```bash
chmod +x config/hooks/normal/enable-myopencvapp.chroot
```

## 5.3. Automatyczne logowanie do sesji graficznej z nodm

Aby aplikacja OpenCV GUI uruchamiała się automatycznie po starcie systemu bez ekranu logowania, możesz użyć menedżera logowania `nodm` (bardzo lekki, idealny do kiosków i systemów embedded).

### Instalacja nodm

Dodaj do pliku `config/package-lists/base.list.chroot`:

```
nodm
```

### Konfiguracja nodm

Utwórz plik autostartu sesji:

```bash
mkdir -p config/includes.chroot/etc/X11/Xsession.d/
nano config/includes.chroot/etc/X11/Xsession.d/99-opencv-autostart
```

Wklej:

```bash
#!/bin/sh
/opt/myopencvapp/venv/bin/python /opt/myopencvapp/app.py
```

Nadaj uprawnienia:

```bash
chmod +x config/includes.chroot/etc/X11/Xsession.d/99-opencv-autostart
```

W pliku `config/includes.chroot/etc/default/nodm` ustaw automatyczne logowanie:

```bash
mkdir -p config/includes.chroot/etc/default
nano config/includes.chroot/etc/default/nodm
```

Wklej:

```
NODM_ENABLED=true
NODM_USER=root
```

---

> **Uwaga:**  
> `nodm` to minimalistyczny menedżer logowania, który automatycznie loguje wybranego użytkownika do sesji graficznej bez pytania o hasło.  
> Dzięki temu aplikacja GUI startuje natychmiast po uruchomieniu systemu, bez ekranu logowania.  
> Rozwiązanie to jest szczególnie polecane do systemów typu kiosk, panel operatorski HMI, urządzenia embedded lub demo.

---

## 6. Zabezpieczenie folderu aplikacji

Aby ograniczyć dostęp do folderu `/opt/myopencvapp` tylko dla roota:

W pliku hooka `config/hooks/normal/install-opencvapp.chroot` dodaj na końcu:

```bash
chmod 700 /opt/myopencvapp
chown root:root /opt/myopencvapp
```

---

## 7. Budowanie obrazu ISO

Aby zbudować własny obraz ISO Debiana z przygotowaną konfiguracją, uruchom poniższe polecenie w katalogu projektu:

```bash
sudo lb build
```

---

## 8. Najczęstsze problemy

> :warning: **Problem:** Okno OpenCV nie otwiera się na pełnym ekranie  
> **Rozwiązanie:** Upewnij się, że masz zainstalowane `xorg` i środowisko graficzne (`xfce4`).

> :warning: **Problem:** Brak zależności Python  
> **Rozwiązanie:** Sprawdź, czy plik `requirements.txt` znajduje się w `/opt/myopencvapp` i czy hook instalacyjny działa poprawnie.

---

## 9. Struktura katalogów

```
moj-debian-part3/
├── config/
│   ├── includes.chroot/
│   │   ├── opt/
│   │   │   └── myopencvapp/
│   │   │       ├── app.py
│   │   │       └── requirements.txt
│   │   └── etc/
│   │       └── systemd/
│   │           └── system/
│   │               └── myopencvapp.service
│   ├── package-lists/
│   │   ├── base.list.chroot
│   │   └── python.list.chroot
│   └── hooks/
│       └── normal/
│           ├── install-opencvapp.chroot
│           └── enable-myopencvapp.chroot
```

---

## 10. Przydatne linki

- [OpenCV – dokumentacja](https://docs.opencv.org/)
- [live-build lb_config – dokumentacja konfiguracji](https://manpages.debian.org/unstable/live-build/lb_config.1.en.html)
- [Oficjalna dokumentacja Debian Live Systems](https://wiki.debian.org/DebianLive)
- [Podstawy systemd – usługi w Debianie](https://wiki.debian.org/systemd)

---

## 11. Autor i licencja

- Autor: [Sebastian Bartel](https://github.com/SebastianSebastianB)
- E-mail: umbraos@icloud.com
- Licencja: MIT

---