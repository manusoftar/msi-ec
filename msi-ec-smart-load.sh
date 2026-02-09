#!/bin/bash

# Script inteligente de carga de msi-ec
# Detecta si estamos en laptop MSI antes de cargar el módulo

# Obtener información del fabricante
MANUFACTURER=$(sudo dmidecode -s system-manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')
PRODUCT=$(sudo dmidecode -s system-product-name 2>/dev/null)

# Log
echo "Detectando hardware..."
echo "Fabricante: $MANUFACTURER"
echo "Producto: $PRODUCT"

# Verificar si es MSI
if echo "$MANUFACTURER" | grep -qi "micro-star\|msi"; then
    echo "✓ Laptop MSI detectada - Cargando módulo msi-ec..."
    
    # Remover módulo del kernel si existe
    modprobe -r msi-ec 2>/dev/null || true
    rmmod msi_ec 2>/dev/null || true
    
    # Cargar módulo personalizado
    if [ -f /home/manusoftar/Git/msi-ec/msi-ec.ko ]; then
        insmod /home/manusoftar/Git/msi-ec/msi-ec.ko
        
        if [ $? -eq 0 ]; then
            echo "✓ Módulo msi-ec cargado exitosamente"
            exit 0
        else
            echo "✗ Error al cargar módulo msi-ec"
            exit 1
        fi
    else
        echo "✗ Módulo no encontrado en /home/manusoftar/Git/msi-ec/msi-ec.ko"
        exit 1
    fi
else
    echo "ℹ No es laptop MSI ($MANUFACTURER) - Saltando carga de msi-ec"
    exit 0
fi
