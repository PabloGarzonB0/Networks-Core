#!/bin/bash
# Monitoreo en tiempo real de eventos de auditoría

LOG_DIR="/var/log/veeam-security"
mkdir -p "$LOG_DIR"

echo "Monitoreando eventos de seguridad..."
echo "Presiona Ctrl+C para detener"

tail -f /var/log/audit/audit.log | while read line; do
    if echo "$line" | grep -q "veeam_"; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] ALERTA: $line" | tee -a "$LOG_DIR/security_events.log"
    fi
done
