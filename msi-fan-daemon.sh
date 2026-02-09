#!/bin/bash

# MSI Fan Control Daemon
# Ajusta automáticamente el modo de ventilador según temperatura

MSI_EC="/sys/devices/platform/msi-ec"
LOG_FILE="/var/log/msi-fan-daemon.log"

# Umbrales de temperatura (ajustables)
TEMP_CRITICAL=80    # > 80°C -> modo advanced
TEMP_HIGH=70        # 70-80°C -> modo auto
TEMP_NORMAL=60      # < 60°C -> modo silent

# Tiempo entre comprobaciones (segundos)
CHECK_INTERVAL=5

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_max_temp() {
    local cpu_temp=0
    local gpu_temp=0
    local acpi_temp=0
    
    # CPU desde MSI EC
    if [ -f "$MSI_EC/cpu/realtime_temperature" ]; then
        cpu_temp=$(cat "$MSI_EC/cpu/realtime_temperature" 2>/dev/null || echo 0)
    fi
    
    # GPU desde MSI EC
    if [ -f "$MSI_EC/gpu/realtime_temperature" ]; then
        gpu_temp=$(cat "$MSI_EC/gpu/realtime_temperature" 2>/dev/null || echo 0)
    fi
    
    # ACPI desde sensors
    acpi_temp=$(sensors 2>/dev/null | grep -A 1 "acpitz-acpi-0" | grep "temp1" | awk '{print $2}' | sed 's/+//;s/°C//;s/\..*//' || echo 0)
    
    # Retornar la temperatura máxima
    local max_temp=$cpu_temp
    [ $gpu_temp -gt $max_temp ] && max_temp=$gpu_temp
    [ $acpi_temp -gt $max_temp ] && max_temp=$acpi_temp
    
    echo $max_temp
}

set_fan_mode() {
    local mode=$1
    local current_mode=$(cat "$MSI_EC/fan_mode" 2>/dev/null)
    
    if [ "$current_mode" != "$mode" ]; then
        echo "$mode" > "$MSI_EC/fan_mode" 2>/dev/null
        if [ $? -eq 0 ]; then
            log "Modo cambiado: $current_mode -> $mode"
        else
            log "ERROR: No se pudo cambiar a modo $mode"
        fi
    fi
}

# Verificar que msi-ec está disponible
if [ ! -d "$MSI_EC" ]; then
    log "ERROR: msi-ec no está disponible en $MSI_EC"
    exit 1
fi

log "=== MSI Fan Control Daemon iniciado ==="
log "Umbrales: CRITICAL>$TEMP_CRITICAL°C, HIGH>$TEMP_HIGH°C, NORMAL<$TEMP_NORMAL°C"

# Loop principal
while true; do
    max_temp=$(get_max_temp)
    
    # Decidir modo según temperatura
    if [ $max_temp -ge $TEMP_CRITICAL ]; then
        # Crítico: modo advanced + opcional cooler boost
        set_fan_mode "advanced"
        # Descomentar para activar cooler boost automáticamente en temperaturas críticas
        # echo "on" > "$MSI_EC/cooler_boost" 2>/dev/null
    elif [ $max_temp -ge $TEMP_HIGH ]; then
        # Alto: modo auto
        set_fan_mode "auto"
        # echo "off" > "$MSI_EC/cooler_boost" 2>/dev/null
    elif [ $max_temp -ge $TEMP_NORMAL ]; then
        # Normal: modo auto (balance)
        set_fan_mode "auto"
    else
        # Bajo: modo silent
        set_fan_mode "silent"
    fi
    
    sleep $CHECK_INTERVAL
done
