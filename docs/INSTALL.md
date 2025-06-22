Вот дополненный файл `INSTALL.md` с разделом по установке системы мониторинга, интегрированный с существующей структурой:

```markdown
# Установка VPN-инфраструктуры и мониторинга

## Требования
### Для всех компонентов
- **ОС**: Ubuntu 22.04 LTS
- **Доступ**: SSH с правами sudo

### VPN/PKI Сервер (10.10.3.82)
- **Ресурсы**: 2 ГБ RAM, 10 ГБ дискового пространства
- **Порты**: 
  - 1194/UDP (OpenVPN)
  - 9176/TCP (OpenVPN Exporter)

### Сервер мониторинга (10.12.0.220)
- **Ресурсы**: 4 ГБ RAM, 20 ГБ дискового пространства
- **Порты**:
  - 9090/TCP (Prometheus)
  - 9115/TCP (Blackbox Exporter)
  - 3000/TCP (Grafana, опционально)

---

## 1. Установка VPN и PKI
```bash
# На сервере 10.10.3.82:
git clone https://github.com/Zarinec/devops-vpn-project.git
cd devops-vpn-project

# Установка PKI
sudo ./scripts/pki-setup.sh

# Настройка VPN
sudo ./scripts/vpn-setup.sh

# Установка конфигов
sudo dpkg -i packages/easy-rsa-config.deb
```

---

## 2. Установка системы мониторинга
### На сервере 10.12.0.220:
```bash
# Установка пакетов мониторинга
sudo dpkg -i packages/prometheus-config.deb 
sudo dpkg -i packages/node-exporter.deb
sudo dpkg -i packages/blackbox-exporter.deb

# Запуск сервисов
sudo systemctl enable --now prometheus node-exporter blackbox-exporter
```

### Настройка мониторинга VPN (на 10.10.3.82):
```bash
sudo dpkg -i packages/openvpn-exporter.deb
sudo systemctl enable --now openvpn-exporter
```

---

## 3. Проверка работы
### Команды для проверки:
| Компонент       | Проверочная команда                     | Ожидаемый результат |
|-----------------|----------------------------------------|---------------------|
| Prometheus      | `curl -s http://localhost:9090/-/healthy` | `Prometheus is Healthy` |
| OpenVPN Exporter| `curl http://10.10.3.82:9176/metrics`  | Метрики в формате Prometheus |
| Blackbox        | `curl "http://localhost:9115/probe?target=10.10.3.82:1194&module=tcp_connect"` | `probe_success 1` |

---

## 4. Настройка Grafana (опционально)
```bash
sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```
1. Откройте `http://10.12.0.220:3000`
2. Добавьте источник данных:
   - Тип: Prometheus
   - URL: `http://localhost:9090`
3. Импортируйте дашборды из `configs/grafana-dashboards/`

---

## Логи и диагностика
| Компонент       | Путь к логам                  | Команда для проверки         |
|-----------------|-------------------------------|------------------------------|
| Prometheus      | `/var/log/prometheus.log`     | `journalctl -u prometheus -n 50` |
| Node Exporter   | `/var/log/node_exporter.log`  | `curl http://localhost:9100/metrics` |
| VPN-мониторинг  | `/var/log/openvpn-exporter.log` | `ss -tulnp \| grep 9176` |

---

> Полная документация по мониторингу: [MONITORING_GUIDE.md](docs/MONITORING_GUIDE.md)
```
