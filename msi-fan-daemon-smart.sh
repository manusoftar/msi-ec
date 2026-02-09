#!/bin/bash

# Verificar si estamos en laptop MSI antes de ejecutar daemon
MANUFACTURER=$(sudo dmidecode -s system-manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')

if ! echo "$MANUFACTURER" | grep -qi "micro-star\|msi"; then
    echo "No es laptop MSI - Daemon no necesario"
    exit 0
fi

# Verificar que msi-ec está disponible
if [ ! -d /sys/devices/platform/msi-ec ]; then
    echo "msi-ec no está cargado - Saliendo"
    exit 1
fi

# Ejecutar daemon original
exec /usr/local/bin/msi-fan-daemon-original
