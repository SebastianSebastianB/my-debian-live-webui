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
