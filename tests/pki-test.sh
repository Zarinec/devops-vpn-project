#!/bin/bash

# Скрипт проверки работоспособности PKI
# Требует настроенного Easy-RSA и root-прав

source "$(dirname "$0")/common.sh"

init_log

log "Начало тестирования PKI инфраструктуры..."

# Проверка базовых директорий
check_dir "/etc/easy-rsa" || {
    log "ОШИБКА: Директория Easy-RSA не найдена!"
    exit 1
}

check_dir "/etc/easy-rsa/pki" || {
    log "ОШИБКА: PKI директория не найдена!"
    exit 1
}

# Проверка ключевых файлов
CA_FILES=(
    "/etc/easy-rsa/pki/ca.crt"
    "/etc/easy-rsa/pki/private/ca.key"
    "/etc/easy-rsa/pki/index.txt"
    "/etc/easy-rsa/pki/crl.pem"
)

for file in "${CA_FILES[@]}"; do
    check_file "$file" || {
        log "ОШИБКА: Не найден критичный файл $file"
        exit 1
    }
done

# Проверка срока действия CA сертификата
log "Проверка срока действия CA сертификата..."
openssl x509 -in /etc/easy-rsa/pki/ca.crt -checkend 86400 -noout || {
    log "ВНИМАНИЕ: CA сертификат истекает в ближайшие 24 часа!"
}

# Проверка CRL
log "Проверка списка отозванных сертификатов..."
openssl crl -in /etc/easy-rsa/pki/crl.pem -text -noout || {
    log "ОШИБКА: Невалидный CRL файл!"
    exit 1
}

# Тестовая генерация сертификата
TEST_CLIENT="testuser_$(date +%s)"
log "Генерация тестового сертификата ($TEST_CLIENT)..."

cd /etc/easy-rsa || exit 1
./easyrsa gen-req "$TEST_CLIENT" nopass 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось сгенерировать тестовый запрос!"
    exit 1
}

echo "yes" | ./easyrsa sign-req client "$TEST_CLIENT" 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось подписать тестовый сертификат!"
    exit 1
}

# Проверка сертификата
log "Проверка валидности тестового сертификата..."
openssl verify -CAfile /etc/easy-rsa/pki/ca.crt /etc/easy-rsa/pki/issued/"$TEST_CLIENT".crt || {
    log "ОШИБКА: Тестовый сертификат невалиден!"
    exit 1
}

# Отзыв тестового сертификата
log "Отзыв тестового сертификата..."
echo "yes" | ./easyrsa revoke "$TEST_CLIENT" 2>&1 | tee -a "$LOG_FILE"
./easyrsa gen-crl 2>&1 | tee -a "$LOG_FILE"

log "Проверка отзыва..."
openssl verify -CRLfile /etc/easy-rsa/pki/crl.pem -CAfile /etc/easy-rsa/pki/ca.crt /etc/easy-rsa/pki/issued/"$TEST_CLIENT".crt 2>&1 | grep -q "certificate revoked" || {
    log "ОШИБКА: Не удалось отозвать тестовый сертификат!"
    exit 1
}

log "✅ Все тесты PKI пройдены успешно!"
exit 0
