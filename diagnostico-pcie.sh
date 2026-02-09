#!/bin/bash

# Diagnóstico completo del estado PCIe
# Para MSI Vector GP68HX - Troubleshooting GPU

echo "═══════════════════════════════════════════════════════════"
echo "  Diagnóstico PCIe - MSI Vector GP68HX"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo

echo "1. DISPOSITIVOS PCI/PCIe DETECTADOS"
echo "───────────────────────────────────────────────────────────"
lspci | grep -E "VGA|3D|Display|NVIDIA"
echo

echo "2. GPU NVIDIA - INFORMACIÓN DETALLADA"
echo "───────────────────────────────────────────────────────────"
GPU_BUS=$(lspci | grep -i nvidia | grep -i vga | awk '{print $1}')

if [ -z "$GPU_BUS" ]; then
    echo "⚠️  ERROR: GPU NVIDIA NO DETECTADA EN PCIe"
    echo "Esto es CRÍTICO - la GPU no está visible en el bus PCIe"
else
    echo "✓ GPU encontrada en: $GPU_BUS"
    
    # Link status completo
    echo
    echo "Estado del enlace PCIe:"
    sudo lspci -vv -s $GPU_BUS 2>/dev/null | grep -E "LnkCap|LnkSta|LnkCtl"
    
    # Capacidades
    echo
    echo "Capacidades PCIe:"
    sudo lspci -vv -s $GPU_BUS 2>/dev/null | grep -E "Speed|Width"
    
    # ASPM
    echo
    echo "ASPM (Power Management):"
    sudo lspci -vv -s $GPU_BUS 2>/dev/null | grep -i "aspm"
fi

echo
echo "3. BRIDGE/SWITCH PCIe (Puente de la GPU)"
echo "───────────────────────────────────────────────────────────"
# El bridge suele ser el dispositivo padre en la jerarquía
BRIDGE=$(lspci | grep -i "PCI bridge" | grep "03:01.0")
if [ ! -z "$BRIDGE" ]; then
    echo "$BRIDGE"
    sudo lspci -vv -s 03:01.0 2>/dev/null | grep -E "Memory|Prefetchable|Control"
else
    echo "Buscando bridges relacionados..."
    lspci | grep -i "PCI bridge" | head -5
fi

echo
echo "4. MÓDULOS NVIDIA CARGADOS"
echo "───────────────────────────────────────────────────────────"
lsmod | grep -i nvidia

echo
echo "5. ESTADO ACTUAL DE LA GPU (nvidia-smi)"
echo "───────────────────────────────────────────────────────────"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=index,name,pci.bus_id,temperature.gpu,power.draw,clocks.gr,clocks.mem,pstate --format=csv
else
    echo "nvidia-smi no disponible"
fi

echo
echo "6. TEMPERATURAS ACTUALES"
echo "───────────────────────────────────────────────────────────"
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
CPU_TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | awk '{print $4}')
ACPI_TEMP=$(sensors 2>/dev/null | grep "acpitz-acpi-0" -A 2 | grep "temp1" | awk '{print $2}')

echo "GPU:  $GPU_TEMP°C"
echo "CPU:  $CPU_TEMP"
echo "ACPI: $ACPI_TEMP"

echo
echo "7. ERRORES PCIe EN LOGS (últimas 24 horas)"
echo "───────────────────────────────────────────────────────────"
sudo journalctl --since "24 hours ago" | grep -iE "pcieport|AER|pci.*error|Link Down|Card not present" | tail -20

echo
echo "8. ERRORES NVIDIA EN LOGS (últimas 24 horas)"
echo "───────────────────────────────────────────────────────────"
sudo journalctl --since "24 hours ago" | grep -i nvidia | grep -iE "error|failed|timeout" | tail -10

echo
echo "9. RECOMENDACIONES"
echo "───────────────────────────────────────────────────────────"

# Verificar si hubo errores PCIe
PCIE_ERRORS=$(sudo journalctl --since "24 hours ago" | grep -icE "Link Down|Card not present")

if [ "$PCIE_ERRORS" -gt 0 ]; then
    echo "⚠️  SE DETECTARON $PCIE_ERRORS ERRORES PCIe EN LAS ÚLTIMAS 24H"
    echo
    echo "Acciones recomendadas:"
    echo "  1. Verificar conexión física de la GPU"
    echo "  2. Revisar cables de alimentación (6-pin/8-pin)"
    echo "  3. Verificar temperaturas durante carga"
    echo "  4. Considerar actualizar BIOS/UEFI de MSI"
    echo "  5. Verificar configuración de PCIe en BIOS"
    echo
    echo "Para monitoreo continuo ejecuta:"
    echo "  ./monitor-pcie.sh"
else
    echo "✓ No se detectaron errores PCIe críticos en las últimas 24 horas"
fi

echo
echo "═══════════════════════════════════════════════════════════"
echo "  Diagnóstico completo"
echo "═══════════════════════════════════════════════════════════"
