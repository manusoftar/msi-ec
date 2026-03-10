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

is_integer() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

safe_temp() {
    # Returns only integer values; invalid/empty values become 0.
    if is_integer "$1"; then
        echo "$1"
    else
        echo 0
    fi
}

read_ec_temp() {
    local path="$1"
    local value=0

    if [ -f "$path" ]; then
        value=$(cat "$path" 2>/dev/null)
    fi

    safe_temp "$value"
}

read_acpi_temp() {
    local value
    value=$(sensors 2>/dev/null | awk '/acpitz-acpi-0/{f=1;next} f&&/temp1/{print $2; exit}')
    value=$(echo "$value" | sed 's/+//; s/\xC2\xB0C//; s/\..*//')
    safe_temp "$value"
}

temperature_state() {
    local t="$1"
    if [ "$t" -ge "$TEMP_CRITICAL" ]; then
        echo "CRITICAL"
    elif [ "$t" -ge "$TEMP_HIGH" ]; then
        echo "HIGH"
    else
        echo "NORMAL"
    fi
}

color_for_state() {
    case "$1" in
        CRITICAL) echo "\033[1;31m" ;;
        HIGH) echo "\033[1;33m" ;;
        *) echo "\033[1;32m" ;;
    esac
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_max_temp() {
    local cpu_temp=0
    local gpu_temp=0
    local acpi_temp=0
    
    # CPU y GPU desde MSI EC
    cpu_temp=$(read_ec_temp "$MSI_EC/cpu/realtime_temperature")
    gpu_temp=$(read_ec_temp "$MSI_EC/gpu/realtime_temperature")

    # ACPI desde sensors
    acpi_temp=$(read_acpi_temp)
    
    # Retornar la temperatura máxima
    local max_temp=$cpu_temp
    [ "$gpu_temp" -gt "$max_temp" ] && max_temp=$gpu_temp
    [ "$acpi_temp" -gt "$max_temp" ] && max_temp=$acpi_temp
    
    echo $max_temp
}

print_line() {
    local label="$1"
    local value="$2"
    local state="$3"
    local color
    color=$(color_for_state "$state")
    printf "%b%-10s %3s C   %-8s\033[0m\n" "$color" "$label" "$value" "$state"
}

render_monitor_screen() {
    local cpu_temp gpu_temp acpi_temp max_temp state mode cpu_fan gpu_fan

    cpu_temp=$(read_ec_temp "$MSI_EC/cpu/realtime_temperature")
    gpu_temp=$(read_ec_temp "$MSI_EC/gpu/realtime_temperature")
    acpi_temp=$(read_acpi_temp)
    max_temp=$(get_max_temp)
    mode=$(cat "$MSI_EC/fan_mode" 2>/dev/null || echo "unknown")
    cpu_fan=$(cat "$MSI_EC/cpu/realtime_fan_speed" 2>/dev/null || echo "N/A")
    gpu_fan=$(cat "$MSI_EC/gpu/realtime_fan_speed" 2>/dev/null || echo "N/A")

    state=$(temperature_state "$max_temp")

    clear
    echo "==============================================="
    echo " MSI Fan Monitor"
    echo "==============================================="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Fan mode: $mode"
    echo "Thresholds: CRITICAL >= $TEMP_CRITICAL C | HIGH >= $TEMP_HIGH C | NORMAL < $TEMP_HIGH C"
    echo

    print_line "CPU" "$cpu_temp" "$(temperature_state "$cpu_temp")"
    print_line "GPU" "$gpu_temp" "$(temperature_state "$gpu_temp")"
    print_line "ACPI" "$acpi_temp" "$(temperature_state "$acpi_temp")"

    echo
    print_line "MAX" "$max_temp" "$state"
    echo
    echo "CPU fan: $cpu_fan RPM"
    echo "GPU fan: $gpu_fan RPM"
    echo
    echo "Press Ctrl+C to exit"
}

run_monitor() {
    while true; do
        render_monitor_screen
        sleep 1
    done
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

if [ "$1" = "monitor" ]; then
    # Use Python Rich-based monitor for better display without flickering
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    PYTHON_MONITOR="$SCRIPT_DIR/msi-fan-monitor.py"
    
    # Try multiple possible locations for the Python monitor
    if [ -f "$PYTHON_MONITOR" ]; then
        exec python3 "$PYTHON_MONITOR"
    elif [ -f "/usr/local/bin/msi-fan-monitor.py" ]; then
        exec python3 /usr/local/bin/msi-fan-monitor.py
    elif [ -f "/home/manusoftar/Git/msi-ec/msi-fan-monitor.py" ]; then
        exec python3 /home/manusoftar/Git/msi-ec/msi-fan-monitor.py
    else
        echo "ERROR: msi-fan-monitor.py not found" >&2
        echo "Falling back to bash monitor..." >&2
        run_monitor
    fi
    exit 0
fi

log "=== MSI Fan Control Daemon iniciado ==="
log "Umbrales: CRITICAL>$TEMP_CRITICAL C, HIGH>$TEMP_HIGH C, NORMAL<$TEMP_NORMAL C"

# Loop principal
while true; do
    max_temp=$(get_max_temp)
    
    # Decidir modo según temperatura
    if [ "$max_temp" -ge "$TEMP_CRITICAL" ]; then
        # Crítico: modo advanced + opcional cooler boost
        set_fan_mode "advanced"
        # Descomentar para activar cooler boost automáticamente en temperaturas críticas
        # echo "on" > "$MSI_EC/cooler_boost" 2>/dev/null
    elif [ "$max_temp" -ge "$TEMP_HIGH" ]; then
        # Alto: modo auto
        set_fan_mode "auto"
        # echo "off" > "$MSI_EC/cooler_boost" 2>/dev/null
    elif [ "$max_temp" -ge "$TEMP_NORMAL" ]; then
        # Normal: modo auto (balance)
        set_fan_mode "auto"
    else
        # Bajo: modo silent
        set_fan_mode "silent"
    fi
    
    sleep $CHECK_INTERVAL
done
