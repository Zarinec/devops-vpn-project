#!/bin/bash

LOG_FILE="/var/log/vpn-install.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "ОШИБКА: Команда $1 не найдена"
        exit 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        log "ОШИБКА: Файл $1 не существует"
        exit 1
    fi
}

check_dir() {
    if [ ! -d "$1" ]; then
        log "ОШИБКА: Директория $1 не существует"
        exit 1
    fi
}

init_log() {
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    log "Начало установки"
}
