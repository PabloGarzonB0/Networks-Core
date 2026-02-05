#!/bin/bash

echo "=========================================="
echo "PRUEBA DE LAS 6 CAPAS DE SEGURIDAD"
echo "=========================================="
echo ""

FILE="/mnt/veeamrepo/test_backup_2025.vbk"

echo "Archivo de prueba: $FILE"
echo ""

# CAPA 4: Read-Only Mount
echo " PRUEBA CAPA 4: READ-ONLY MOUNT"
MOUNT_STATE=$(mount | grep veeamrepo | grep -o "ro\|rw")
echo "Estado actual: $MOUNT_STATE"
if [ "$MOUNT_STATE" = "ro" ]; then
    echo " Repositorio en modo READ-ONLY (protegido)"
    echo "Intentando eliminar archivo..."
    rm "$FILE" 2>&1 | head -1
else
    echo "  Repositorio en modo READ-WRITE (ventana de backup)"
fi
echo ""

# CAPA 1: Inmutabilidad
echo " PRUEBA CAPA 1: INMUTABILIDAD DEL KERNEL"
IMMUTABLE=$(lsattr "$FILE" 2>/dev/null | grep -o "i")
if [ "$IMMUTABLE" = "i" ]; then
    echo " Archivo contiene atributos inmutable"
    echo "Intentando eliminar archivo..."
    rm "$FILE" 2>&1 | head -1
    echo "Intentando modificar archivo..."
    echo "HACK" >> "$FILE" 2>&1 | head -1
else
    echo " Archivo NO tiene atributo inmutable"
fi
echo ""

# CAPA 2: AppArmor
echo " PRUEBA CAPA 2: APPARMOR"
AA_STATUS=$(aa-status 2>/dev/null | grep -c "profiles are in enforce mode")
if [ "$AA_STATUS" -gt 0 ]; then
    echo " AppArmor activo"
    echo "Intentando remover inmutabilidad..."
    chattr -i "$FILE" 2>&1 | head -1
else
    echo " AppArmor NO está activo"
fi
echo ""

# CAPA 3: auditd
echo " PRUEBA CAPA 3: AUDITD"
if systemctl is-active --quiet auditd; then
    RULES=$(auditctl -l 2>/dev/null | grep -c veeam)
    echo " auditd activo - $RULES reglas de Veeam cargadas"
    echo "Eventos recientes:"
    ausearch -k veeam_delete_attempt -ts recent 2>/dev/null | grep -c "type=SYSCALL" | xargs echo "  - Intentos de eliminación detectados:"
else
    echo " auditd NO está activo"
fi
echo ""

# CAPA 5: Fail2ban
echo " PRUEBA CAPA 5: FAIL2BAN"
if systemctl is-active --quiet fail2ban; then
    echo " Fail2ban activo"
    fail2ban-client status sshd 2>/dev/null | grep "Currently banned"
else
    echo " Fail2ban NO está activo"
fi
echo ""

# CAPA 6: Monitoreo
echo " PRUEBA CAPA 6: MONITOREO CONTINUO"
if [ -f "/opt/veeam-security/scripts/security_monitor.sh" ]; then
    echo " Script de monitoreo existe"
    CRON_CHECK=$(crontab -l 2>/dev/null | grep -c security_monitor)
    if [ "$CRON_CHECK" -gt 0 ]; then
        echo " Monitoreo automatizado con cron"
    else
        echo " Monitoreo NO está en cron"
    fi
    echo "Última verificación:"
    tail -3 /var/log/veeam-security/security_status.log 2>/dev/null
else
    echo " Script de monitoreo NO existe"
fi
echo ""

echo "=========================================="
echo "PRUEBAS COMPLETADAS"
echo "=========================================="
