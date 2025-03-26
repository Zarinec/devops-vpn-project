#!/bin/bash

source "$(dirname "$0")/common.sh"

init_log

# Проверка прав
if [ "$(id -u)" -ne 0 ]; then
    log "ОШИБКА: Скрипт должен быть запущен с правами root!"
    exit 1
fi

# Проверка зависимостей
check_command easyrsa
check_command openssl

# Конфигурация
EASY_RSA_DIR="/etc/easy-rsa"
PKI_DIR="$EASY_RSA_DIR/pki"

log "Установка Easy-RSA..."
apt-get install -y easy-rsa 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось установить easy-rsa"
    exit 1
}

log "Создание структуры директорий..."
mkdir -p "$EASY_RSA_DIR" "$PKI_DIR" || {
    log "ОШИБКА: Не удалось создать директории"
    exit 1
}

log "Инициализация PKI..."
cd "$EASY_RSA_DIR" || exit 1
./easyrsa init-pki 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось инициализировать PKI"
    exit 1
}

log "Генерация корневого сертификата..."
echo "My Company CA" | ./easyrsa build-ca nopass 2>&1 | tee -a "$LOG_FILE" || {
    log "ОШИБКА: Не удалось сгенерировать CA"
    exit 1
}

log "Настройка прав доступа..."
chmod 700 "$PKI_DIR"
chmod 600 "$PKI_DIR/private/ca.key"
chmod 644 "$PKI_DIR/ca.crt"

log "PKI успешно настроен!"
