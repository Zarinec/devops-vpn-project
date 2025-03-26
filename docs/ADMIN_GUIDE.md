# Руководство администратора VPN-инфраструктуры

## Содержание
1. [Генерация пользовательских сертификатов](#генерация-пользовательских-сертификатов)
2. [Управление сертификатами](#управление-сертификатами)
3. [Мониторинг](#мониторинг)
4. [Резервное копирование](#резервное-копирование)

---

## Генерация пользовательских сертификатов

### Создание сертификата для нового пользователя
```bash
sudo ./scripts/gen-client-cert.sh <имя_клиента>
Пример:
sudo ./scripts/gen-client-cert.sh ivanov
Результат:
- Файл конфигурации: /etc/openvpn/client-configs/ivanov.ovpn
- Сертификат и ключ в PKI: /etc/easy-rsa/pki/issued/ivanov.crt, /etc/easy-rsa/pki/private/ivanov.key

### Отзыв сертификата
cd /etc/easy-rsa
./easyrsa revoke <имя_клиента>
./easyrsa gen-crl
sudo systemctl restart openvpn-server@server
---

## Управление сертификатами
- Все сертификаты хранятся в /etc/easy-rsa/pki/
- Список выданных сертификатов:
  ls /etc/easy-rsa/pki/issued/
  
- Список отозванных сертификатов:
 
  cat /etc/easy-rsa/pki/crl.pem | openssl crl -text -noout
  
---

## Мониторинг
- Логи OpenVPN: /var/log/openvpn.log
- Логи генерации сертификатов: /var/log/vpn-install.log
- Статус подключений:
 
  sudo cat /var/log/openvpn-status.log
  
---
## Резервное копирование
Критичные данные для резервирования:
/etc/easy-rsa/pki/
/etc/openvpn/
/var/log/vpn-install.log
Команда для создания резервной копии:
tar -czvf /backup/vpn-backup-$(date +%F).tar.gz \
  /etc/easy-rsa/pki \
  /etc/openvpn \
  /var/log/vpn-install.log
---
> Важно  
> Не храните приватные ключи (`*.key`) в Git! Используйте .gitignore.
---

### **Дополнительные улучшения**

1. **Автоматическая проверка срока действия сертификатов**  
   Добавьте в `crontab`:
   ```bash
   0 3 * * * /usr/bin/find /etc/easy-rsa/pki/issued/ -name "*.crt" -exec openssl x509 -checkend 86400 -noout -in {} \; -print | mail -s "Expiring VPN Certs" admin@testcompany.com
   
2. Шаблон `.gitignore`  
   Добавьте в корень репозитория:
  
   *.key
   *.ovpn
   *.log
   pki/

### Проверка работоспособности
1. Сгенерируйте тестовый сертификат:
  
   sudo ./scripts/gen-client-cert.sh testuser
   
2. Проверьте содержимое .ovpn файла:
  
   cat /etc/openvpn/client-configs/testuser.ovpn
   
3.Попробуйте подключиться через OpenVPN-клиент.

---

## Настройка сетевой маршрутизации и firewall

### Текущие правила iptables
Для просмотра текущих правил:
```bash
iptables -L -n -v
iptables -t nat -L -n -v
### Управление правилами
1. Добавить правило:
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
2. Удалить правило:
iptables -D INPUT <номер_правила>
iptables-save > /etc/iptables/rules.v4
### Проверка маршрутизации
1.Посмотреть NAT-правила:
sudo iptables -t nat -L POSTROUTING -n -v
2. Проверить форвардинг:
cat /proc/sys/net/ipv4/ip_forward  # Должно быть 1
3. Тестирование подключения:
# С клиента VPN:
ping 8.8.8.8
ping 8.8.4.4
curl ifconfig.me
### Важные файлы
- /etc/iptables/rules.v4 - сохраненные правила firewall
- /etc/sysctl.conf - настройки ядра
- /var/log/openvpn-status.log - статус подключений

## **Дополнительные улучшения**

1. **Скрипт для сброса правил** (`scripts/reset-firewall.sh`):
```bash
#!/bin/bash
iptables -F
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables-save > /etc/iptables/rules.v4
echo "Firewall rules reset to default!"
2. Автоматический бэкап правил (добавить в cron):
0 3 * * * /sbin/iptables-save > /backup/iptables-backup-$(date +\%F).rules
3. Проверка открытых портов:
ss -tulnp | grep -E '1194|22'
