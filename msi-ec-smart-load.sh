#!/bin/bash

# Script inteligente de carga de msi-ec
# Detecta si estamos en laptop MSI antes de cargar el módulo

#
# Exit Codes:
#   0 - Success: Module loaded or not an MSI laptop (graceful skip)
#   1 - Module file not found (likely not built yet)
#   2 - Module file not readable (permission issue)
#   3 - Module load failed (kernel/compatibility issue)

MODULE_PATH="/home/manusoftar/Git/msi-ec/msi-ec.ko"

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
    
    # Step 1: Check if module file exists
    if [ ! -f "$MODULE_PATH" ]; then
        echo "ERROR: Module file not found at $MODULE_PATH" >&2
        echo "Please build the module first using 'make' or 'sudo make dkms-install'" >&2
        exit 1
    fi
    
    # Step 2: Check if module file is readable
    if [ ! -r "$MODULE_PATH" ]; then
        echo "ERROR: Module file not readable: permission denied" >&2
        echo "File exists at $MODULE_PATH but cannot be read" >&2
        echo "Check file permissions with: ls -l $MODULE_PATH" >&2
        exit 2
    fi
    
    # Step 3: Remove pre-existing module if loaded
    modprobe -r msi-ec 2>/dev/null || true
    rmmod msi_ec 2>/dev/null || true
    
        # Step 4: Load the module with detailed error capture
        if ! insmod "$MODULE_PATH" 2>&1; then
            ERROR_OUTPUT=$(insmod "$MODULE_PATH" 2>&1)
            echo "ERROR: Failed to load module: $ERROR_OUTPUT" >&2
            echo "Module file: $MODULE_PATH" >&2
            echo "This may indicate a kernel compatibility issue or permission problem" >&2
            echo "Check kernel logs: sudo dmesg | tail -20" >&2
            exit 3
        fi
    
        echo "✓ Módulo msi-ec cargado exitosamente"
        exit 0
else
    echo "ℹ No es laptop MSI ($MANUFACTURER) - Saltando carga de msi-ec"
    exit 0
fi
