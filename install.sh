#!/bin/bash

set -e

echo "Installing Process Monitoring Solution with Systemd"

CURRENT_DIR=$(pwd)

SCRIPT_PATH="/usr/local/bin/T3_DevOps_monitoring.sh"
CONFIG_DIR="/etc/monitoring"
CONFIG_FILE="$CONFIG_DIR/T3_DevOps_config.conf"
SERVICE_FILE="/etc/systemd/system/T3_DevOps_monitoring.service"
TIMER_FILE="/etc/systemd/system/T3_DevOps_monitoring.timer"

echo "Creating directories..."
sudo mkdir -p /usr/local/bin
sudo mkdir -p "$CONFIG_DIR"

#Создание процесса test 
echo "Creating test process..."
sudo tee /usr/local/bin/test << 'EOF' > /dev/null
#!/bin/bash
# Test process for monitoring demonstration
while true; do
    sleep 60
done
EOF

sudo chmod +x /usr/local/bin/test
/usr/local/bin/test &

echo "Installing monitoring script..."
sudo cp "$CURRENT_DIR/T3_DevOps_monitoring.sh" "$SCRIPT_PATH"
sudo chmod +x "$SCRIPT_PATH"

sudo cp "$CURRENT_DIR/T3_DevOps_config.conf" "$CONFIG_FILE"
sudo chmod 644 "$CONFIG_FILE"

echo "Creating log file..."
sudo touch /var/log/monitoring.log
sudo chmod 644 /var/log/monitoring.log

# Создание systemd service файла
echo "Creating systemd service..."
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=T3 DevOps Monitoring Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
User=root
ExecStart=$SCRIPT_PATH
Environment=CONFIG_FILE=$CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF

# Создание systemd timer файла
echo "Creating systemd timer..."
sudo tee "$TIMER_FILE" > /dev/null << EOF
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

sudo chmod 644 "$SERVICE_FILE"
sudo chmod 644 "$TIMER_FILE"

sudo systemctl daemon-reload
#----------------------------------Для демонстрации---------------------------------------
#Создание systemd service для процесса test
echo "Creating test process systemd service..."
sudo tee /etc/systemd/system/test-process.service > /dev/null << EOF
[Unit]
Description=Test Process for Monitoring
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/test
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# Включаем автозапуск процесса test
sudo systemctl enable test-process.service
sudo systemctl start test-process.service
#-----------------------------------------------------------------------------------

echo "Enabling and starting timer..."
sudo systemctl enable T3_DevOps_monitoring.timer
sudo systemctl start T3_DevOps_monitoring.timer

echo ""
echo "=== INSTALLATION COMPLETED SUCCESSFULLY ==="
echo ""
echo "Files installed:"
echo "  Script: $SCRIPT_PATH"
echo "  Config: $CONFIG_FILE"
echo "  Service: $SERVICE_FILE"
echo "  Timer: $TIMER_FILE"
echo "  Log: /var/log/monitoring.log"
echo "  Test process: /usr/local/bin/test (PID: $(pgrep -f '/usr/local/bin/test' | head -1))"
echo ""
