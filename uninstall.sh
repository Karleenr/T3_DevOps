#!/bin/bash

set -e

echo "Uninstalling T3 DevOps Monitoring Solution"

echo "Stopping test process..."
pkill -f "/usr/local/bin/test" 2>/dev/null || true

sudo systemctl stop T3_DevOps_monitoring.timer 2>/dev/null || true
sudo systemctl disable T3_DevOps_monitoring.timer 2>/dev/null || true
sudo systemctl stop T3_DevOps_monitoring.service 2>/dev/null || true

sudo rm -f /etc/systemd/system/T3_DevOps_monitoring.service
sudo rm -f /etc/systemd/system/T3_DevOps_monitoring.timer

sudo rm -f /usr/local/bin/T3_DevOps_monitoring.sh
sudo rm -f /usr/local/bin/test
sudo rm -rf /etc/monitoring

sudo systemctl daemon-reload
echo "Uninstallation completed successfully!"
