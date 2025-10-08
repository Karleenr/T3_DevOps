# Решение для мониторинга процессов

Bash-скрипт для мониторинга процесса "test" в среде Linux с интеграцией systemd.

## Возможности

- ✅ Мониторит процесс "test" каждую минуту через systemd timer
- ✅ Отправляет HTTPS запросы когда процесс запущен
- ✅ Логирует перезапуски процессов в `/var/log/monitoring.log`
- ✅ Логирует недоступность сервера мониторинга
- ✅ Запускается автоматически при старте системы
- ✅ Соответствует техническому заданию

## Выполненные требования ТЗ

1. **Запускаться при запуске системы** - интеграция с systemd timer
2. **Отрабатывать каждую минуту** - systemd OnCalendar=*:*:00
3. **Если процесс запущен** - отправка HTTPS запроса на сервер мониторинга
4. **Если процесс был перезапущен** - запись в лог `/var/log/monitoring.log`
5. **Если сервер мониторинга не доступен** - запись в лог

## Структура проекта

├── README.md

├── install.sh # Скрипт установки

├── uninstall.sh # Скрипт удаления

├── T3_DevOps_monitoring.sh # Основной скрипт мониторинга

└── T3_DevOps_config.conf # Файл конфигурации


## Установка

### Требования
- Linux система с systemd
- Доступ sudo
- Установленный curl

### Быстрая установка

```bash
# Клонировать репозиторий
git clone <repository-url>
cd T3_DevOps

# Дать права на выполнение
chmod +x install.sh uninstall.sh T3_DevOps_monitoring.sh

# Установить
sudo ./install.sh


# Скопировать файлы
sudo mkdir -p /etc/monitoring
sudo cp T3_DevOps_monitoring.sh /usr/local/bin/
sudo cp T3_DevOps_config.conf /etc/monitoring/
sudo chmod +x /usr/local/bin/T3_DevOps_monitoring.sh

# Создать процесс test (обязательно!)
sudo tee /usr/local/bin/test << 'EOF'
#!/bin/bash
while true; do sleep 60; done
EOF
sudo chmod +x /usr/local/bin/test
/usr/local/bin/test &

# Создать systemd файлы
sudo tee /etc/systemd/system/T3_DevOps_monitoring.service > /dev/null << EOF
[Unit]
Description=T3 DevOps Monitoring Service
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/T3_DevOps_monitoring.sh
Environment=CONFIG_FILE=/etc/monitoring/T3_DevOps_config.conf

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/T3_DevOps_monitoring.timer > /dev/null << EOF
[Unit]
Description=Run T3 DevOps monitoring every minute
Requires=T3_DevOps_monitoring.service

[Timer]
OnCalendar=*:*:00
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Запустить сервис
sudo systemctl daemon-reload
sudo systemctl enable T3_DevOps_monitoring.timer
sudo systemctl start T3_DevOps_monitoring.timer
```

## Конфигурация 

### Имя процесса для мониторинга
```PROCESS_NAME="/usr/local/bin/test"```

### Путь к файлу логов
```LOG_PATH="/var/log/monitoring.log"```

### URL сервера мониторинга
```ADDRESS="https://test.com/monitoring/test/api"```

### Файл для хранения PID процесса
```PID_FILE="/var/run/monitoring.pid"```


## Использование
### Проверка статуса
```systemctl status T3_DevOps_monitoring.timer```
### Просмотр логов
```tail -f /var/log/monitoring.log```
### Ручной запуск
```systemctl start T3_DevOps_monitoring.service```
### Остановка мониторинга
```systemctl stop T3_DevOps_monitoring.timer```
### Удаление
```sudo ./uninstall.sh```


## Важные заметки
### Обязательное условие
Для работы скрипта должен быть запущен процесс с именем ```test```. При установке автоматически создается тестовый процесс.

### Настройка процесса test
Если нужно изменить процесс для мониторинга, отредактируйте переменную ```PROCESS_NAME``` в конфигурационном файле.

### Настройка URL мониторинга
Замените https://test.com/monitoring/test/api на реальный URL вашего сервера мониторинга.

## Логирование

### Формат логов

```
2024-01-15 10:30:01 INFO: Process "/usr/local/bin/test" was restarted. Old PID: 1234, New PID: 5678
2024-01-15 10:31:01 ERROR: Monitoring server unavailable. HTTP response: 404
2024-01-15 10:32:01 ERROR: Curl failed with exit code 7
```

### События логирования
```
Событие	               Условие	                 Пример лога
Перезапуск процесса	   PID изменился	         INFO: Process was restarted...
Ошибка сервера	       HTTP код не 200/201/204	 ERROR: Monitoring server unavailable...
Ошибка сети	           Curl exit code ≠ 0	     ERROR: Curl failed with exit code...
```

![До ребута](/sсreenshots/before_reboot.png)

![После ребута](/sсreenshots/after_reboot.png)

### Команды для проверка

#### Первый терминал
```tail -f /var/log/monitoring.log```
#### Второй терминал
```
pkill -f "/usr/local/bin/test" && /usr/local/bin/test &
sleep 2
sudo /usr/local/bin/T3_DevOps_monitoring.sh
```