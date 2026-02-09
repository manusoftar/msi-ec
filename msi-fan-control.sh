#!/bin/bash

# Script para controlar ventiladores MSI y monitorear temperaturas
# Para MSI Vector GP68HX 12VH

MSI_EC="/sys/devices/platform/msi-ec"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════"
echo "  Control de Ventiladores MSI Vector GP68HX 12VH"
echo "═══════════════════════════════════════════════════════════"
echo

# Función para mostrar estado actual
show_status() {
    echo -e "${GREEN}═══ ESTADO ACTUAL ═══${NC}"
    
    # Firmware
    if [ -f "$MSI_EC/fw_version" ]; then
        FW=$(cat "$MSI_EC/fw_version")
        echo "Firmware: $FW"
    fi
    
    # Modo de ventilador actual
    if [ -f "$MSI_EC/fan_mode" ]; then
        FAN_MODE=$(cat "$MSI_EC/fan_mode")
        echo -e "Modo ventilador: ${YELLOW}$FAN_MODE${NC}"
    fi
    
    # Cooler Boost
    if [ -f "$MSI_EC/cooler_boost" ]; then
        BOOST=$(cat "$MSI_EC/cooler_boost")
        if [ "$BOOST" = "on" ]; then
            echo -e "Cooler Boost: ${RED}ACTIVADO${NC}"
        else
            echo -e "Cooler Boost: ${GREEN}Desactivado${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}═══ TEMPERATURAS ═══${NC}"
    
    # CPU
    if [ -f "$MSI_EC/cpu/realtime_temperature" ]; then
        CPU_TEMP=$(cat "$MSI_EC/cpu/realtime_temperature")
        CPU_FAN=$(cat "$MSI_EC/cpu/realtime_fan_speed" 2>/dev/null || echo "N/A")
        if [ "$CPU_TEMP" -gt 80 ]; then
            echo -e "CPU: ${RED}${CPU_TEMP}°C${NC} | Ventilador: ${CPU_FAN} RPM"
        elif [ "$CPU_TEMP" -gt 70 ]; then
            echo -e "CPU: ${YELLOW}${CPU_TEMP}°C${NC} | Ventilador: ${CPU_FAN} RPM"
        else
            echo -e "CPU: ${GREEN}${CPU_TEMP}°C${NC} | Ventilador: ${CPU_FAN} RPM"
        fi
    fi
    
    # GPU
    if [ -f "$MSI_EC/gpu/realtime_temperature" ]; then
        GPU_TEMP=$(cat "$MSI_EC/gpu/realtime_temperature")
        GPU_FAN=$(cat "$MSI_EC/gpu/realtime_fan_speed" 2>/dev/null || echo "N/A")
        if [ "$GPU_TEMP" -gt 75 ]; then
            echo -e "GPU: ${RED}${GPU_TEMP}°C${NC} | Ventilador: ${GPU_FAN} RPM"
        elif [ "$GPU_TEMP" -gt 65 ]; then
            echo -e "GPU: ${YELLOW}${GPU_TEMP}°C${NC} | Ventilador: ${GPU_FAN} RPM"
        else
            echo -e "GPU: ${GREEN}${GPU_TEMP}°C${NC} | Ventilador: ${GPU_FAN} RPM"
        fi
    fi
    
    # ACPI Thermal Zone (chipset/placa base)
    ACPI_TEMP=$(sensors 2>/dev/null | grep -A 1 "acpitz-acpi-0" | grep "temp1" | awk '{print $2}' | sed 's/+//;s/°C//')
    if [ ! -z "$ACPI_TEMP" ]; then
        ACPI_TEMP_INT=$(echo "$ACPI_TEMP" | cut -d'.' -f1)
        if [ "$ACPI_TEMP_INT" -gt 80 ]; then
            echo -e "ACPI (Chipset): ${RED}${ACPI_TEMP}°C${NC} ⚠️  CRÍTICO"
        elif [ "$ACPI_TEMP_INT" -gt 70 ]; then
            echo -e "ACPI (Chipset): ${YELLOW}${ACPI_TEMP}°C${NC}"
        else
            echo -e "ACPI (Chipset): ${GREEN}${ACPI_TEMP}°C${NC}"
        fi
    fi
    
    # Temperatura Package (si está disponible via sensors)
    PKG_TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}' | sed 's/+//;s/°C//')
    if [ ! -z "$PKG_TEMP" ]; then
        PKG_TEMP_INT=$(echo "$PKG_TEMP" | cut -d'.' -f1)
        if [ "$PKG_TEMP_INT" -gt 85 ]; then
            echo -e "CPU Package: ${RED}${PKG_TEMP}°C${NC}"
        elif [ "$PKG_TEMP_INT" -gt 75 ]; then
            echo -e "CPU Package: ${YELLOW}${PKG_TEMP}°C${NC}"
        else
            echo -e "CPU Package: ${GREEN}${PKG_TEMP}°C${NC}"
        fi
    fi
    
    echo
}

# Función para cambiar modo de ventilador
set_fan_mode() {
    echo -e "${GREEN}Modos disponibles:${NC}"
    cat "$MSI_EC/available_fan_modes"
    echo
    echo "Modo actual: $(cat $MSI_EC/fan_mode)"
    echo
    read -p "Ingresa el modo deseado (auto/silent/advanced): " MODE
    
    echo "$MODE" | sudo tee "$MSI_EC/fan_mode" > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Modo cambiado a: $MODE${NC}"
    else
        echo -e "${RED}✗ Error al cambiar modo${NC}"
    fi
}

# Función para activar/desactivar Cooler Boost
toggle_cooler_boost() {
    CURRENT=$(cat "$MSI_EC/cooler_boost")
    
    if [ "$CURRENT" = "on" ]; then
        echo "off" | sudo tee "$MSI_EC/cooler_boost" > /dev/null
        echo -e "${GREEN}✓ Cooler Boost desactivado${NC}"
    else
        echo "on" | sudo tee "$MSI_EC/cooler_boost" > /dev/null
        echo -e "${YELLOW}✓ Cooler Boost ACTIVADO (ventiladores al máximo)${NC}"
    fi
}

# Función para monitoreo continuo
monitor() {
    echo -e "${GREEN}Iniciando monitoreo continuo (Ctrl+C para salir)...${NC}"
    echo
    
    while true; do
        clear
        show_status
        sleep 2
    done
}

# Menú principal
if [ "$1" = "status" ] || [ "$1" = "" ]; then
    show_status
elif [ "$1" = "set-mode" ]; then
    set_fan_mode
elif [ "$1" = "boost" ]; then
    toggle_cooler_boost
elif [ "$1" = "monitor" ]; then
    monitor
elif [ "$1" = "auto" ]; then
    echo "auto" | sudo tee "$MSI_EC/fan_mode" > /dev/null
    echo -e "${GREEN}✓ Modo automático activado${NC}"
elif [ "$1" = "silent" ]; then
    echo "silent" | sudo tee "$MSI_EC/fan_mode" > /dev/null
    echo -e "${GREEN}✓ Modo silencioso activado${NC}"
elif [ "$1" = "advanced" ]; then
    echo "advanced" | sudo tee "$MSI_EC/fan_mode" > /dev/null
    echo -e "${GREEN}✓ Modo avanzado activado${NC}"
elif [ "$1" = "help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos:"
    echo "  status      - Mostrar estado actual (por defecto)"
    echo "  monitor     - Monitoreo continuo de temperaturas"
    echo "  set-mode    - Cambiar modo de ventilador interactivamente"
    echo "  auto        - Activar modo automático"
    echo "  silent      - Activar modo silencioso"
    echo "  advanced    - Activar modo avanzado (máximo rendimiento)"
    echo "  boost       - Activar/desactivar Cooler Boost"
    echo "  help        - Mostrar esta ayuda"
    echo
    echo "Temperaturas monitoreadas:"
    echo "  CPU         - Temperatura del procesador (via MSI EC)"
    echo "  GPU         - Temperatura de la tarjeta gráfica (via MSI EC)"
    echo "  ACPI        - Chipset/placa base (ACPI Thermal Zone)"
    echo "  CPU Package - Temperatura del package completo del CPU"
    echo
    echo "Umbrales de temperatura:"
    echo "  CPU:  > 80°C crítico, > 70°C advertencia"
    echo "  GPU:  > 75°C crítico, > 65°C advertencia"
    echo "  ACPI: > 80°C crítico, > 70°C advertencia"
    echo
    echo "Ejemplos:"
    echo "  $0                    # Ver estado"
    echo "  $0 monitor            # Monitorear en tiempo real"
    echo "  $0 advanced           # Modo rendimiento máximo"
    echo "  $0 boost              # Toggle Cooler Boost"
else
    echo "Comando desconocido: $1"
    echo "Usa '$0 help' para ver comandos disponibles"
    exit 1
fi
