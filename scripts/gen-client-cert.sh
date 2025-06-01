#!/bin/bash

# Скрипт для генерации клиентского сертификата OpenVPN
# Требует: Easy-RSA, OpenVPN, права root

# Конфигурация
EASY_RSA_DIR="/etc/easy-rsa"
PKI_DIR="$EASY_RSA_DIR/pki"
OVPN_DIR="/etc/openvpn"
CLIENT_DIR="$OVPN_DIR/client-configs"
LOG_FILE="/var/log/vpn-cert-gen.log"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Проверка прав
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}ОШИБКА: Скрипт должен быть запущен с правами root!${NC}" >&2
    exit 1
fi

# Проверка аргументов
if [ -z "$1" ]; then
    echo -e "${YELLOW}Использование: $0 <имя_пользователя>${NC}"
    echo "Пример: $0 ivanov"
    exit 1
fi

CLIENT_NAME="$1"

# Проверка зависимостей
check_deps() {
    local missing=0
    for cmd in easyrsa openssl; do
        if ! command -v "$cmd" &> /dev/null; then
            log "${RED}ОШИБКА: Не найдена команда $cmd${NC}"
            missing=1
        fi
    done
    [ $missing -eq 1 ] && exit 1
}

# Проверка существования сертификата
check_existing() {
    if [ -f "$PKI_DIR/issued/$CLIENT_NAME.crt" ]; then
        log "${YELLOW}ВНИМАНИЕ: Сертификат для $CLIENT_NAME уже существует!${NC}"
        read -p "Перезаписать? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Генерация сертификата
generate_cert() {
    log "Генерация сертификата для $CLIENT_NAME..."
    
    cd "$EASY_RSA_DIR" || exit 1
    
    # Генерация запроса
    echo -e "\n\n" | ./easyrsa gen-req "$CLIENT_NAME" nopass 2>&1 | tee -a "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log "${RED}ОШИБКА: Не удалось сгенерировать запрос сертификата${NC}"
        exit 1
    fi

    # Подписание сертификата
    echo "yes" | ./easyrsa sign-req client "$CLIENT_NAME" 2>&1 | tee -a "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log "${RED}ОШИБКА: Не удалось подписать сертификат${NC}"
        exit 1
    fi
}

# Генерация конфига клиента
generate_config() {
    log "Создание конфигурации клиента..."
    
    mkdir -p "$CLIENT_DIR"
    
    cat > "$CLIENT_DIR/$CLIENT_NAME.ovpn" <<EOF
client
dev tun
proto udp
remote vpn.example.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat "$PKI_DIR/ca.crt")
</ca>
<cert>
$(openssl x509 -in "$PKI_DIR/issued/$CLIENT_NAME.crt")
</cert>
<key>
$(cat "$PKI_DIR/private/$CLIENT_NAME.key")
</key>
EOF

    chmod 600 "$CLIENT_DIR/$CLIENT_NAME.ovpn"
}

# Основной процесс
main() {
    echo -e "\n${GREEN}=== Генерация сертификата для $CLIENT_NAME ===${NC}"
    
    check_deps
    check_existing
    
    generate_cert
    generate_config
    
    log "${GREEN}Сертификат успешно создан!${NC}"
    log "Файл конфигурации: $CLIENT_DIR/$CLIENT_NAME.ovpn"
    
    echo -e "\n${GREEN}Готово! Отправьте файл ${YELLOW}$CLIENT_DIR/$CLIENT_NAME.ovpn${GREEN} сотруднику.${NC}"
}

main "$@"
