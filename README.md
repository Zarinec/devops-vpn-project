```markdown
# 🛡️ VPN Infrastructure Project

![GitHub](https://img.shields.io/github/license/Zarinec/devops-vpn-project.git)
![GitHub last commit](https://img.shields.io/github/last-commit/Zarinec/devops-vpn-project.git)
![GitHub repo size](https://img.shields.io/github/repo-size/Zarinec/devops-vpn-project.git)

Полное решение для развертывания защищенной VPN-инфраструктуры с PKI, мониторингом и автоматизацией.

## 📌 Основные возможности

- **Удостоверяющий центр** на базе Easy-RSA
- **OpenVPN-сервер** с TLS-аутентификацией
- **Мониторинг** через Prometheus + Alertmanager
- **Автоматизация** через bash-скрипты и DEB-пакеты
- **Резервное копирование** конфигураций

## 🚀 Быстрый старт

### Предварительные требования
- Ubuntu 22.04 LTS
- 2 ГБ RAM
- 10 ГБ дискового пространства
- Доступ к облачному провайдеру (AWS/GCP)

```bash
# Клонирование репозитория
git clone https://github.com/Zarinec/devops-vpn-project.git
```

## 📂 Структура проекта

```

.
├── configs/                  # Конфигурационные файлы
│   ├── server.conf           # Конфиг OpenVPN-сервера
│   ├── client-template.ovpn  # Шаблон для клиентов
│   └── prometheus.yml        # Настройки мониторинга
│
├── docs/                     # Документация
│   ├── ADMIN_GUIDE.md        # Руководство администратора
│   ├── USER_GUIDE_RU.md      # Руководство пользователя
│   ├── INSTALL.md            # Инструкция по установке
│   └── images/               # Диаграммы и скриншоты
│       └── vpn-flow.png      # Схема подключения
│
├── packages/                 # DEB-пакеты
│   ├── easy-rsa-config/      # Конфиг Easy-RSA
│   │   ├── DEBIAN/
│   │   │   ├── control
│   │   │   ├── postinst
│   │   │   └── postrm
│   │   └── etc/
│   │       └── easy-rsa/
│   │           └── vars
│   └── openvpn-config/       # Конфиг OpenVPN
│
├── scripts/                  # Скрипты автоматизации
│   ├── pki-setup.sh          # Установка PKI
│   ├── vpn-setup.sh          # Настройка OpenVPN
│   ├── gen-client-cert.sh    # Генерация клиентских сертификатов
│   ├── monitoring.sh         # Развёртывание мониторинга
│   ├── reset-firewall.sh     # Скрипт для сброса правил firewall
│   ├── revoke-client-cert.sh     # Отзыв клиентского сертификата
│   ├── backup.sh             # Скрипт бэкапа
│   └── common.sh             # Общие функции
│
├── tests/                   # Тесты
│   ├── pki-test.sh          # Тесты PKI
│   └── vpn-test.sh          # Тесты VPN-подключения
│
├── .gitignore               # Исключаемые файлы
└── README.md                # Основная документация проекта

```

## 📚 Документация

| Документ | Описание |
|----------|----------|
| [📘 Руководство администратора](docs/ADMIN_GUIDE.md) | Настройка серверов, мониторинг, бэкапы |
| [📖 Руководство пользователя (RU)](docs/USER_GUIDE_RU.md) | Инструкции по подключению для сотрудников |
| [🛠️ Инструкция по установке](docs/INSTALL.md) | Пошаговое развертывание |

## 🔧 Технические компоненты

### 1. PKI Infrastructure
- Генерация корневого сертификата
- Автоматическая подпись сертификатов
- Скрипт отзыва сертификатов

### 2. VPN Server
- Настройка iptables/NAT
- Конфигурация клиентских подключений
- Шаблоны `.ovpn` файлов

### 3. Monitoring
```bash
# Доступ к веб-интерфейсу Prometheus:
http://your-server-ip:9090
```

## 🤝 Участие в разработке

1. Форкните репозиторий
2. Создайте ветку: `git checkout -b feature/your-feature`
3. Сделайте коммит: `git commit -m 'Add some feature'`
4. Запушьте изменения: `git push origin feature/your-feature`
5. Откройте Pull Request

## ⚠️ Важная информация
i
- **Не храните** приватные ключи в репозитории!
- Все пароли должны быть в `.env` (в `.gitignore`)
- Логи автоматически ротируются в `/var/log/`

### Ключевые особенности:
1. **Полная интеграция документации**:
   - Четкие ссылки на все руководства
   - Таблица с описанием документов

2. **Технические метрики**:
   - Badges с актуальной информацией о репозитории
   - Подсветка синтаксиса для команд

3. **Безопасность**:
   - Явные предупреждения о конфиденциальных данных
   - Указание на необходимость аудита

4. **Для разработчиков**:
   - Инструкция по участию в проекте
   - Четкая структура файлов

