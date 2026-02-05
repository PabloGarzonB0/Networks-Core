#!/bin/bash
# Gestor de ventana de backup

ACTION=$1
LOG_FILE="/var/log/veeam-security/backup_window.log"

case "$ACTION" in
    open)
        echo "[$(date)]  Abriendo ventana de backup" | tee -a "$LOG_FILE"
        /opt/veeam-security/scripts/mount_readwrite.sh
        ;;
    close)
        echo "[$(date)]  Cerrando ventana de backup" | tee -a "$LOG_FILE"
        /opt/veeam-security/scripts/mount_readonly.sh
        ;;
    *)
        echo "Uso: $0 {open|close}"
        exit 1
        ;;
esac
