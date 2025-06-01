# VPN Admin Guide (`devops-vpn-project`)

## 📌 Quick Access
| Действие                  | Скрипт                          | Команда примера                               |
|---------------------------|---------------------------------|-----------------------------------------------|
| Добавить пользователя     | `scripts/gen-client-cert.sh`    | `sudo ./scripts/gen-client-cert.sh ivanov`    |
| Отозвать сертификат       | `scripts/revoke-client-cert.sh` | `sudo ./scripts/revoke-client-cert.sh petrov` |
| Сбросить firewall         | `scripts/reset-firewall.sh`     | `sudo ./scripts/reset-firewall.sh`            |

## 📂 Структура скриптов
devops-vpn-project/
└── scripts/
├── gen-client-cert.sh # Генерация сертификатов
├── revoke-client-cert.sh # Отзыв доступа
└── ... # Остальные скрипты
---

### ** 2. Разделы с привязкой к скриптам **

#### **🔐 Управление пользователями**  
### 1. Добавление пользователя  
Для запуска используйте [этот скрипт](https://github.com/Zarinec/devops-vpn-project/blob/main/scripts/gen-client-cert.sh).  
`scripts/gen-client-cert.sh <username>`  

**Пример:**  
```bash
sudo ./scripts/gen-client-cert.sh ivanov
Где найти файлы:

Конфиг: /etc/openvpn/client-configs/ivanov.ovpn
Сертификат: /etc/easy-rsa/pki/issued/ivanov.crt
Массовое добавление:

```bash
# Подготовьте файл `users.list` с именами
sudo ./scripts/bulk-gen-certs.sh

#### **❌ Отзыв доступа**  
```markdown
### 2. Отзыв сертификата  
Скрипт: `scripts/revoke-client-cert.sh`  

**Команда:**  
```bash
sudo ./scripts/revoke-client-cert.sh petrov && sudo systemctl restart openvpn
Проверка:

```bash
openssl crl -in /etc/easy-rsa/pki/crl.pem -text | grep "petrov"

---

### **3. Интеграция с реальными скриптами**
Для каждого скрипта добавляю **конкретные примеры** из вашего кода:

#### **Пример для `revoke-client-cert.sh`**
```markdown
## 🔄 Автоматизация  
Скрипт автоматически:  
1. Проверяет наличие сертификата (`/etc/easy-rsa/pki/issued/$1.crt`)  
2. Генерирует CRL (`easyrsa gen-crl`)  
3. Перезапускает OpenVPN (`systemctl restart openvpn`)  

**Логи:**  
```bash
tail -f /var/log/vpn-install.log  # Все действия логируются

---

### **4. Визуальные подсказки**
Добавляю **иконки и предупреждения** для удобства:  
```markdown
> ⚠️ **Важно**  
> После отзыва сертификата:  
> - Уведомите пользователя  
> - Обновите бэкапы (`/etc/easy-rsa/pki/`)  

> 💡 **Совет**  
> Для проверки подключений:  
> ```bash  
> cat /var/log/openvpn-status.log | grep "10.8.0."  
> ```
5. Проверка работоспособности

```markdown
## 🧪 Тестирование  
1. Создайте тестового пользователя:  
   ```bash  
   sudo ./scripts/gen-client-cert.sh test_user  
2. Проверьте конфиг:
   ```bash
   cat /etc/openvpn/client-configs/test_user.ovpn | grep "remote"  
3. Подключитесь через OpenVPN-клиент.
```
