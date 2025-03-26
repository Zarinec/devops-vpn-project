#!/bin/bash

source "$(dirname "$0")/common.sh"

init_log

# Проверка прав
if [ "$(id -u)" -ne 0 ]; then
    log "ОШИБКА: Скрипт должен быть запущен с правами root!"
    exit 1
fi

# Проверка зависимостей
check_command openvpn
check_command easyrsa
check_command iptables
check_command sysctl

# Конфигурация
OVPN_DIR="/etc/openvpn"
EASY_RSA_DIR="/etc/easy-rsa"
VPN_NET="10.8.0.0/24"
PUBLIC_IFACE=$(ip route | grep default | awk '{print $5}')

log "Установка OpenVPN..."
apt-get install -y openvpn iptables-persistent 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось установить пакеты"
    exit 1
}

log "Копирование конфигурации сервера..."
check_file "$OVPN_DIR/server.conf"
cp "$OVPN_DIR/server.conf" "$OVPN_DIR/server.conf.bak" || {
    log "ОШИБКА: Не удалось создать backup конфига"
    exit 1
}

# Настройка конфига OpenVPN
cat > "$OVPN_DIR/server.conf" <<EOF
port 1194
proto udp
dev tun
ca $OVPN_DIR/ca.crt
cert $OVPN_DIR/server.crt
key $OVPN_DIR/server.key
dh none
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
EOF

log "Настройка сертификатов..."
check_dir "$EASY_RSA_DIR"
cd "$EASY_RSA_DIR" || exit 1

log "Генерация ключа сервера..."
./easyrsa gen-req server nopass 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось сгенерировать ключ сервера"
    exit 1
}

log "Подпись сертификата сервера..."
echo "yes" | ./easyrsa sign-req server server 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось подписать сертификат"
    exit 1
}

log "Копирование сертификатов..."
cp "$EASY_RSA_DIR/pki/issued/server.crt" "$OVPN_DIR/" && \
cp "$EASY_RSA_DIR/pki/private/server.key" "$OVPN_DIR/" && \
cp "$EASY_RSA_DIR/pki/ca.crt" "$OVPN_DIR/" || {
    log "ОШИБКА: Не удалось скопировать сертификаты"
    exit 1
}

log "Настройка IP-форвардинга..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось применить sysctl"
    exit 1
}

log "Настройка iptables..."
# Очистка правил
iptables -F
iptables -t nat -F

# Базовые правила
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешение локального трафика
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Разрешение установленных соединений
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Разрешение SSH (измените порт при необходимости)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Разрешение OpenVPN
iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# NAT для VPN-клиентов
iptables -t nat -A POSTROUTING -s "$VPN_NET" -o "$PUBLIC_IFACE" -j MASQUERADE

# Разрешение форвардинга для VPN
iptables -A FORWARD -i tun0 -o "$PUBLIC_IFACE" -j ACCEPT
iptables -A FORWARD -i "$PUBLIC_IFACE" -o tun0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Сохранение правил
iptables-save > /etc/iptables/rules.v4 || {
    log "ОШИБКА: Не удалось сохранить правила iptables"
    exit 1
}

log "Запуск OpenVPN..."
systemctl enable --now openvpn-server@server.service 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось запустить OpenVPN"
    exit 1
}

log "Проверка работы VPN..."
ping -c 3 10.8.0.1 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: VPN интерфейс не отвечает"
    exit 1
}

log "OpenVPN успешно настроен с маршрутизацией и firewall!"
