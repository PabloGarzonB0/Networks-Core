#!/bin/bash
# Cambiar repositorio a modo lectura-escritura

LOG_FILE="/var/log/veeam-security/mount_changes.log"

echo "[$(date)] Cambiando a modo READ-WRITE..." | tee -a "$LOG_FILE"

mount -o remount,rw /mnt/veeamrepo

if [ $? -eq 0 ]; then
    echo "[$(date)] Repositorio en modo READ-WRITE" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR al cambiar a READ-WRITE" | tee -a "$LOG_FILE"
fi
