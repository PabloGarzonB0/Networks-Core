#!/bin/bash
# Script de aplicación de inmutabilidad
# Aplica el atributo inmutable a todos los archivos de backup Veeam

LOG_FILE="/var/log/veeam-security/immutability.log"
REPO_PATH="/mnt/veeamrepo"

mkdir -p /var/log/veeam-security

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "=== Iniciando aplicación de inmutabilidad ==="

# Buscar archivos de backup Veeam (.vbk, .vib, .vbm)
find "$REPO_PATH" -type f \( -name "*.vbk" -o -name "*.vib" -o -name "*.vbm" \) | while read file; do
    # Verificar si ya tiene el atributo inmutable
    if ! lsattr "$file" | grep -q "^....i"; then
        chattr +i "$file"
        log_message "Inmutabilidad aplicada: $file"
    fi
done

log_message "=== Proceso completado ==="
