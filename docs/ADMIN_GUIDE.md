# Руководство администратора VPN-инфраструктуры

## Содержание
1. [Назначение документа](#назначение-документа)
2. [Область применения](#область-применения)
3. [Генерация пользовательских сертификатов](#генерация-пользовательских-сертификатов)
4. [Управление сертификатами](#управление-сертификатами)
5. [Мониторинг](#мониторинг)
6. [Резервное копирование](#резервное-копирование)
7. [Дополнительные улучшения](#дополнительные-улучшения)

## 🛡️ Введение

### Назначение документа
Данное руководство предназначено для системных администраторов, отвечающих за:
- Развертывание и обслуживание корпоративного VPN-сервера
- Управление доступом сотрудников через PKI-инфраструктуру
- Обеспечение безопасности сетевых подключений

### Область применения
Система используется для:
1. Защищенного удаленного доступа к внутренним ресурсам компании
2. Разграничения прав доступа между отделами
3. Аудит подключений через механизм отзыва сертификатов

---

## Генерация пользовательских сертификатов

### Создание сертификата для нового пользователя
Чтобы добавить нового пользователя VPN используйте [этот скрипт](https://github.com/Zarinec/devops-vpn-project/blob/main/scripts/gen-client-cert.sh "gen-client-cert.sh")
  > Скрипт создает сразу сертификат пользователя и файл .ovpn, который нербходимо передать новому пользователю VPN!
<u>Как использовать:</u>
Сохраните скрипт в /scripts/gen-client-cert.sh
Дайте права на выполнение:
```bash
sudo ./scripts/gen-client-cert.sh <имя_клиента>
```
Пример:
```bash
sudo ./scripts/gen-client-cert.sh ivanov
```
Результат:
- Файл конфигурации: /etc/openvpn/client-configs/ivanov.ovpn
- Сертификат и ключ в PKI: /etc/easy-rsa/pki/issued/ivanov.crt, /etc/easy-rsa/pki/private/ivanov.key

## Отзыв сертификатов
Для запуска используйте [этот скрипт](https://github.com/Zarinec/devops-vpn-project/blob/main/scripts/revoke-client-cert.sh "revoke-client-cert.sh")
```bash
# Просмотр выданных сертификатов
ls /etc/easy-rsa/pki/issued/
```
### 1. Отзыв сертификата
```bash
sudo ./scripts/revoke-client-cert.sh <имя_клиента>
```
### 2. Проверка CRL
```bash
openssl crl -in /etc/easy-rsa/pki/crl.pem -text -noout
```
Для **автоматического обновления** CRL добавьте в cron:
   ```bash
   # Еженедельное обновление CRL
   0 3 * * 1 /etc/easy-rsa/easyrsa gen-crl
   ```
---

## Управление сертификатами
- Все сертификаты хранятся в ```bash /etc/easy-rsa/pki/```
- Список выданных сертификатов:
  ```bash
  ls /etc/easy-rsa/pki/issued/
  ```
- Список отозванных сертификатов:
  ```bash 
  cat /etc/easy-rsa/pki/crl.pem | openssl crl -text -noout
  ```  
---

## Мониторинг
- Логи OpenVPN: /var/log/openvpn.log
- Логи генерации сертификатов: /var/log/vpn-install.log
- Статус подключений:
  ```bash
  sudo cat /var/log/openvpn-status.log
  ```
---

## Резервное копирование
Критичные данные для резервирования:
/etc/easy-rsa/pki/
/etc/openvpn/
/var/log/vpn-install.log
Команда для создания резервной копии:
```bash
tar -czvf /backup/vpn-backup-$(date +%F).tar.gz \
  /etc/easy-rsa/pki \
  /etc/openvpn \
  /var/log/vpn-install.log
```
---

> Важно!!!  
> Не храните приватные ключи (`*.key`) в Git! Используйте .gitignore.

---

### **Дополнительные улучшения**

1. **Автоматическая проверка срока действия сертификатов**  
   Добавьте в `crontab`:
   ```bash
   0 3 * * * /usr/bin/find /etc/easy-rsa/pki/issued/ -name "*.crt" -exec openssl x509 -checkend 86400 -noout -in {} \; -print | mail -s "Expiring VPN Certs" admin@testcompany.com
   ```
2. Шаблон `.gitignore`  
   Добавьте в корень репозитория:
  ```
   *.key \
   *.ovpn \
   *.log \
   pki/
   ```
### Проверка работоспособности
1. Сгенерируйте тестовый сертификат:
```bash  
   sudo ./scripts/gen-client-cert.sh testuser
```   
2. Проверьте содержимое .ovpn файла:
```bash  
   cat /etc/openvpn/client-configs/testuser.ovpn
```   
3.Попробуйте подключиться через OpenVPN-клиент.

---

## Настройка сетевой маршрутизации и firewall

### Текущие правила iptables
Для просмотра текущих правил:
```bash
iptables -L -n -v
iptables -t nat -L -n -v
```
### Управление правилами
1. Добавить правило:
```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```
2. Удалить правило:
```bash
iptables -D INPUT <номер_правила>
iptables-save > /etc/iptables/rules.v4
```
## Проверка маршрутизации
### 1.Посмотреть NAT-правила:
Для просмотра текущих правил:
```bash
sudo iptables -t nat -L -n -v --line-numbers
```
**Что смотрим:**
- Наличие правила MASQUERADE для VPN-подсети
- Интерфейс, через который идет NAT (обычно eth0 или ens3)
Пример корректного вывода:
```
Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1     1534 125K MASQUERADE  all  --  *      eth0    10.8.0.0/24          0.0.0.0/0
```
### 2. Проверить форвардинг:
Системный форвардинг:
```bash
cat /proc/sys/net/ipv4/ip_forward 
```
* 1 - форвардинг включен (корректно)
* 0 - требуется включить в /etc/sysctl.conf
Форвардинг пакетов:
```bash
sudo iptables -L FORWARD -n -v
```
Ожидаемый результат:
```
Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 125K   15M ACCEPT     all  --  tun0   eth0    0.0.0.0/0            0.0.0.0/0
  98K 4857K ACCEPT     all  --  eth0   tun0    0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
```
### 3. Тестирование подключения:
# С клиента VPN:
```
ping 8.8.8.8
ping 8.8.4.4
curl ifconfig.me
```
### Важные файлы
- /etc/iptables/rules.v4 - сохраненные правила firewall
- /etc/sysctl.conf - настройки ядра
- /var/log/openvpn-status.log - статус подключений

## **Дополнительные улучшения**

1. **Скрипт для сброса правил** (`scripts/reset-firewall.sh`):

Для сброса правил используйте [этот скрипт](https://github.com/Zarinec/devops-vpn-project/blob/main/scripts/reset-firewall.sh "reset-firewall.sh")

2. Автоматический бэкап правил (добавить в cron):
```bash
0 3 * * * /sbin/iptables-save > /backup/iptables-backup-$(date +\%F).rules
```
3. Проверка открытых портов:
Для проверки открытых портов, можно использовать команду:
```bash
ss -tulnp | grep -E '1194|22'
```
  > !!!Набор портов может отличаться
