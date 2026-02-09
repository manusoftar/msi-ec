#!/bin/bash

# Monitor especializado en errores PCIe
# Enfocado en detectar desconexiones de GPU y problemas de bus

LOG_FILE="$HOME/log-pcie-errors.txt"
CRITICAL_LOG="$HOME/log-pcie-CRITICO.txt"

# Keywords PCIe críticos
PCIE_KEYWORDS="pcieport.*Link Down|pcieport.*Card not present|pcieport.*cannot fit|AER.*Corrected error|AER.*Uncorrected|AER.*Fatal error|ASPM.*inconsistent|bridge window.*cannot fit|pci.*error|GPU.*fallen off|nvidia.*lost"

echo "═══════════════════════════════════════════════════════════"
echo "  Monitor de Errores PCIe - MSI Vector GP68HX"
echo "  Vigilando: GPU NVIDIA, Slots PCIe, Bridge errors"
echo "═══════════════════════════════════════════════════════════"
echo

# Mostrar estado inicial del PCIe
echo "Estado inicial del sistema:"
echo "---"
lspci | grep -i vga
echo "---"
lspci | grep -i nvidia
echo "---"
echo

# Verificar slot PCIe de la GPU
GPU_BUS=$(lspci | grep -i nvidia | grep VGA | awk '{print $1}')
if [ ! -z "$GPU_BUS" ]; then
    echo "GPU encontrada en bus PCIe: $GPU_BUS"
    GPU_LINK_SPEED=$(sudo lspci -vv -s $GPU_BUS 2>/dev/null | grep "LnkSta:" | head -1)
    echo "Link status: $GPU_LINK_SPEED"
else
    echo "⚠️  ADVERTENCIA: No se detectó GPU NVIDIA en PCIe"
fi

echo
echo "Iniciando monitoreo continuo... (Ctrl+C para detener)"
echo

# Contadores
LINK_DOWN_COUNT=0
CARD_MISSING_COUNT=0
MEMORY_ERROR_COUNT=0

journalctl -f | stdbuf -oL grep -iE --line-buffered "$PCIE_KEYWORDS" | while read -r line; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Obtener temperaturas
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
    CPU_TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | awk '{print $4}' | sed 's/+//')
    ACPI_TEMP=$(sensors 2>/dev/null | grep "acpitz-acpi-0" -A 2 | grep "temp1" | awk '{print $2}' | sed 's/+//')
    
    # Determinar tipo de error PCIe
    ERROR_TYPE="PCIe Error"
    SEVERITY="⚠️  WARNING"
    COLOR="\e[33m"  # Amarillo
    
    if echo "$line" | grep -qi "Link Down"; then
        ERROR_TYPE="🔴 CRÍTICO: PCIe LINK DOWN"
        SEVERITY="CRÍTICO"
        COLOR="\e[31m"
        LINK_DOWN_COUNT=$((LINK_DOWN_COUNT + 1))
    elif echo "$line" | grep -qi "Card not present"; then
        ERROR_TYPE="🔴 CRÍTICO: TARJETA DESCONECTADA"
        SEVERITY="CRÍTICO"
        COLOR="\e[31m"
        CARD_MISSING_COUNT=$((CARD_MISSING_COUNT + 1))
    elif echo "$line" | grep -qi "cannot fit"; then
        ERROR_TYPE="🔴 CRÍTICO: ERROR DE MEMORIA PCIe"
        SEVERITY="CRÍTICO"
        COLOR="\e[31m"
        MEMORY_ERROR_COUNT=$((MEMORY_ERROR_COUNT + 1))
    elif echo "$line" | grep -qi "Fatal error"; then
        ERROR_TYPE="🔴 CRÍTICO: ERROR FATAL PCIe"
        SEVERITY="CRÍTICO"
        COLOR="\e[31m"
    elif echo "$line" | grep -qi "Uncorrected"; then
        ERROR_TYPE="🟠 ERROR NO CORREGIBLE"
        SEVERITY="ERROR"
        COLOR="\e[33m"
    fi
    
    # Construir reporte
    REPORT="[$ERROR_TYPE] $TIMESTAMP
LOG: $line
TEMPS: GPU: ${GPU_TEMP}°C | CPU: ${CPU_TEMP} | ACPI: ${ACPI_TEMP}
Contadores: Link Down: $LINK_DOWN_COUNT | Card Missing: $CARD_MISSING_COUNT | Memory Errors: $MEMORY_ERROR_COUNT
------------------------------------------------------------------------"
    
    # Mostrar con color
    echo -e "${COLOR}${REPORT}\e[0m"
    
    # Guardar en log
    echo "$REPORT" >> "$LOG_FILE"
    
    # Si es crítico, guardar en log separado
    if [ "$SEVERITY" = "CRÍTICO" ]; then
        echo "$REPORT" >> "$CRITICAL_LOG"
        
        # Notificación urgente
        notify-send -u critical "🔥 ERROR PCIe CRÍTICO" "$ERROR_TYPE\nGPU: ${GPU_TEMP}°C\nRevisar conexión física"
        
        # Beep de alerta
        for i in {1..3}; do
            echo -e "\a"
            sleep 0.2
        done &
        
        # Si hay múltiples Link Down, sugerir acción
        if [ $LINK_DOWN_COUNT -ge 3 ]; then
            echo -e "\e[31m"
            echo "═══════════════════════════════════════════════════════════"
            echo "  ⚠️  ALERTA: MÚLTIPLES DESCONEXIONES PCIe DETECTADAS"
            echo "═══════════════════════════════════════════════════════════"
            echo "  Acciones recomendadas:"
            echo "  1. Verificar conexión física de la GPU (reseat)"
            echo "  2. Revisar cables de alimentación de la GPU"
            echo "  3. Verificar temperaturas (posible throttling térmico)"
            echo "  4. Revisar logs completos: cat $CRITICAL_LOG"
            echo "═══════════════════════════════════════════════════════════"
            echo -e "\e[0m"
        fi
    fi
    
    sleep 1
done
