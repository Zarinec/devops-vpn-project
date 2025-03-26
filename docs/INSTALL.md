# Установка VPN-инфраструктуры

## Требования
- Ubuntu 22.04 LTS
- 2 ГБ RAM
- 10 ГБ дискового пространства

## Пошаговая установка
1. Установите PKI:
   ```bash
   sudo ./scripts/pki-setup.sh
   
2. Настройте VPN-сервер:
   ```bash  
   sudo ./scripts/vpn-setup.sh
   
3. Установите конфигурационный пакет:
   ```bash
   sudo dpkg -i packages/easy-rsa-config.deb
   
Логи установки доступны в:
- /var/log/vpn-install.log
- /var/log/easy-rsa-config-install.log

