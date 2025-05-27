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
