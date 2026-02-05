#!/bin/bash
# Cambiar repositorio a modo solo lectura

LOG_FILE="/var/log/veeam-security/mount_changes.log"

echo "[$(date)] Cambiando a modo READ-ONLY..." | tee -a "$LOG_FILE"

mount -o remount,ro /mnt/veeamrepo

if [ $? -eq 0 ]; then
    echo "[$(date)] Repositorio en modo READ-ONLY" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR al cambiar a READ-ONLY" | tee -a "$LOG_FILE"
fi
