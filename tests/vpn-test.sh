#!/bin/bash

# Скрипт проверки работоспособности VPN сервера
# Требует настроенного OpenVPN и root-прав

source "$(dirname "$0")/common.sh"

init_log

log "Начало тестирования VPN сервера..."

# Проверка сервиса OpenVPN
check_command systemctl
systemctl is-active openvpn-server@server >/dev/null || {
    log "ОШИБКА: Сервис OpenVPN не запущен!"
    exit 1
}

# Проверка портов
log "Проверка открытых портов..."
ss -tulnp | grep -E ':1194\b' | grep openvpn || {
    log "ОШИБКА: OpenVPN не слушает на порту 1194!"
    exit 1
}

# Проверка tun интерфейса
log "Проверка сетевого интерфейса..."
ip a show tun0 >/dev/null || {
    log "ОШИБКА: Интерфейс tun0 не найден!"
    exit 1
}

# Проверка маршрутизации
log "Проверка правил iptables..."
iptables -t nat -L POSTROUTING -n -v | grep -q "10.8.0.0/24" || {
    log "ОШИБКА: Не найдены NAT правила для VPN!"
    exit 1
}

# Проверка доступа в интернет через VPN
log "Проверка доступа в интернет через VPN..."
ping -c 3 -I tun0 8.8.8.8 >/dev/null || {
    log "ОШИБКА: Нет доступа в интернет через VPN!"
    exit 1
}

# Проверка DNS
log "Проверка DNS разрешения через VPN..."
dig +short google.com @8.8.8.8 -b 10.8.0.1 >/dev/null || {
    log "ОШИБКА: Проблемы с DNS через VPN!"
    exit 1
}

# Проверка клиентского подключения (имитация)
log "Имитация клиентского подключения..."
TEST_FILE="/tmp/vpn_test_$(date +%s)"
echo "test" > "$TEST_FILE"
sudo openvpn --config /etc/openvpn/client-template.ovpn --dev null --verb 0 --auth-nocache --connect-timeout 10 --ping 1 --ping-exit 1 || {
    log "ОШИБКА: Не удалось имитировать клиентское подключение!"
    rm -f "$TEST_FILE"
    exit 1
}
rm -f "$TEST_FILE"

log "✅ Все тесты VPN сервера пройдены успешно!"
exit 0
