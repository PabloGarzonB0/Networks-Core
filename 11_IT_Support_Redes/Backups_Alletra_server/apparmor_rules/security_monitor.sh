#!/bin/bash

# ===========================================================
# SCRIPT DE MONITOREO DE SEGURIDAD GENERAL
# ===========================================================


# Rutas de confguracion de archivos log - Veam backup 
LOG_FILE="/var/log/veeam-security/security_status.log"
ALERT_FILE="/var/log/veeam-security/security_alerts.log"

mkdir -p /var/log/veeam-security


# Funcion de reporte de log
log_event() {
    local severity="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$severity] $message" >> "$LOG_FILE"

    if [ "$severity" = "CRITICAL" ] || [ "$severity" = "WARNING" ]; then
        echo "[$timestamp] $message" >> "$ALERT_FILE"
    fi
}

log_event "INFO" "=== INICIO DE VERIFICACION DE SEGURIDAD ==="

# 1. Verificar AppArmor
if systemctl is-active --quiet apparmor; then
    PROFILES_ENFORCED=$(aa-status --enforced 2>/dev/null | wc -l)
    log_event "INFO" "AppArmor activo - $PROFILES_ENFORCED perfiles en modo enforce"
else
    log_event "CRITICAL" "AppArmor NO esta activo"
fi

# 2. Verificar audit
if systemctl is-active --quiet auditd; then
    AUDIT_RULES=$(auditctl -l 2>/dev/null | wc -l)
    log_event "INFO" "auditd activo - $AUDIT_RULES reglas cargadas"
else
    log_event "CRITICAL" "auditd NO esta activo"
fi

# 3. Verificar Fail2ban
if systemctl is-active --quiet fail2ban; then
    BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}')
    if [ -z "$BANNED_IPS" ]; then
        BANNED_IPS=0
    fi
    if [ "$BANNED_IPS" -gt 0 ] 2>/dev/null; then
        log_event "WARNING" "Fail2ban: $BANNED_IPS IPs baneadas actualmente"
    else
        log_event "INFO" "Fail2ban activo - Sin IPs baneadas"
    fi
else
    log_event "CRITICAL" "Fail2ban NO esta activo"
fi

# 4. Verificar estado del repositorio
REPO_STATE=$(mount | grep /mnt/veeamrepo | grep -o "ro\|rw" | head -1)
if [ "$REPO_STATE" = "ro" ]; then
    log_event "INFO" "Repositorio en modo READ-ONLY (protegido)"
elif [ "$REPO_STATE" = "rw" ]; then
    CURRENT_HOUR=$(date +%H)
    if [ "$CURRENT_HOUR" = "14" ]; then
        log_event "INFO" "Repositorio en modo READ-WRITE (ventana de backup)"
    else
        log_event "WARNING" "Repositorio en modo READ-WRITE fuera de ventana de backup"
    fi
else
    log_event "CRITICAL" "No se pudo determinar estado del repositorio"
fi

# 5. Verificar espacio en disco
DISK_USAGE=$(df -h /mnt/veeamrepo 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
if [ -z "$DISK_USAGE" ]; then
    log_event "WARNING" "No se pudo obtener uso de disco"
else
    if [ "$DISK_USAGE" -gt 90 ] 2>/dev/null; then
        log_event "CRITICAL" "Espacio en disco critico: ${DISK_USAGE}%"
    elif [ "$DISK_USAGE" -gt 80 ] 2>/dev/null; then
        log_event "WARNING" "Espacio en disco alto: ${DISK_USAGE}%"
    else
        log_event "INFO" "Espacio en disco OK: ${DISK_USAGE}%"
    fi
fi

# 6. Verificar servicios críticos
CRITICAL_SERVICES="ssh apparmor auditd fail2ban cron"
for service in $CRITICAL_SERVICES; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log_event "INFO" "Servicio $service: activo"
    else
        log_event "CRITICAL" "Servicio $service: INACTIVO"
    fi
done

log_event "INFO" "=== FIN DE VERIFICACION DE SEGURIDAD ==="
