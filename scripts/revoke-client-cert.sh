#!/bin/bash

# Скрипт для отзыва клиентского сертификата VPN
# Требует прав root и настроенного Easy-RSA

source "$(dirname "$0")/common.sh"

init_log

# Проверка прав
if [ "$(id -u)" -ne 0 ]; then
    log "ОШИБКА: Скрипт должен быть запущен с правами root!"
    exit 1
fi

# Проверка аргументов
if [ -z "$1" ]; then
    log "Использование: $0 <имя_клиента>"
    log "Пример: $0 ivanov"
    exit 1
fi

CLIENT_NAME="$1"
EASY_RSA_DIR="/etc/easy-rsa"
PKI_DIR="$EASY_RSA_DIR/pki"
CRL_FILE="$PKI_DIR/crl.pem"

# Проверка зависимостей
check_command easyrsa
check_command openssl
check_command systemctl

# Проверка существования сертификата
check_file "$PKI_DIR/issued/$CLIENT_NAME.crt" || {
    log "ОШИБКА: Сертификат для клиента $CLIENT_NAME не найден!"
    exit 1
}

log "Начинаем отзыв сертификата для клиента $CLIENT_NAME..."

# Отзыв сертификата
cd "$EASY_RSA_DIR" || exit 1
log "Выполняем отзыв через Easy-RSA..."
echo "yes" | ./easyrsa revoke "$CLIENT_NAME" 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось отозвать сертификат!"
    exit 1
}

# Генерация CRL (Certificate Revocation List)
log "Генерируем новый список отозванных сертификатов (CRL)..."
./easyrsa gen-crl 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось сгенерировать CRL!"
    exit 1
}

# Проверка CRL
check_file "$CRL_FILE" || {
    log "ОШИБКА: Файл CRL не был создан!"
    exit 1
}

# Копирование CRL для OpenVPN
log "Копируем CRL в директорию OpenVPN..."
cp "$CRL_FILE" "/etc/openvpn/server/" || {
    log "ОШИБКА: Не удалось скопировать CRL!"
    exit 1
}

# Перезагрузка OpenVPN
log "Перезапускаем OpenVPN для применения изменений..."
systemctl restart openvpn-server@server 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось перезапустить OpenVPN!"
    exit 1
}

# Проверка отзыва
log "Проверяем статус отзыва..."
openssl verify -CRLfile "$CRL_FILE" -CAfile "$PKI_DIR/ca.crt" "$PKI_DIR/issued/$CLIENT_NAME.crt" 2>&1 | tee -a "$LOG_FILE" | grep -q "certificate revoked" || {
    log "ОШИБКА: Сертификат не появился в списке отозванных!"
    exit 1
}

log "✅ Сертификат $CLIENT_NAME успешно отозван!"
log "Список отозванных сертификатов: $CRL_FILE"
log "Не забудьте уведомить клиента о блокировке доступа!"

exit 0
