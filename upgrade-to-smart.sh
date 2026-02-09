#!/bin/bash

# Actualizar instalación para que funcione en MSI y Dell

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════"
echo "  Actualización a versión multi-laptop"
echo "  Compatible con MSI Vector + Dell Latitude"
echo "═══════════════════════════════════════════════════════════"
echo

# 1. Detener servicios actuales
echo "Paso 1: Deteniendo servicios actuales..."
sudo systemctl stop msi-fan-daemon.service 2>/dev/null || true
sudo systemctl stop msi-ec-custom.service 2>/dev/null || true
echo -e "${GREEN}✓ Servicios detenidos${NC}"

# 2. Instalar versión inteligente del cargador de módulo
echo
echo "Paso 2: Instalando cargador inteligente de módulo..."
sudo cp msi-ec-smart-load.sh /usr/local/bin/msi-ec-smart-load
sudo chmod +x /usr/local/bin/msi-ec-smart-load

# Reemplazar servicio
sudo cp msi-ec-smart.service /etc/systemd/system/msi-ec-custom.service
echo -e "${GREEN}✓ Cargador inteligente instalado${NC}"

# 3. Actualizar daemon
echo
echo "Paso 3: Actualizando daemon..."

# Renombrar daemon original
if [ -f /usr/local/bin/msi-fan-daemon ]; then
    sudo mv /usr/local/bin/msi-fan-daemon /usr/local/bin/msi-fan-daemon-original
fi

# Instalar wrapper inteligente
sudo cp msi-fan-daemon-smart.sh /usr/local/bin/msi-fan-daemon
sudo chmod +x /usr/local/bin/msi-fan-daemon

echo -e "${GREEN}✓ Daemon actualizado${NC}"

# 4. Recargar systemd
echo
echo "Paso 4: Recargando systemd..."
sudo systemctl daemon-reload
echo -e "${GREEN}✓ Systemd recargado${NC}"

# 5. Reiniciar servicios
echo
echo "Paso 5: Reiniciando servicios..."
sudo systemctl start msi-ec-custom.service
sudo systemctl start msi-fan-daemon.service

# Verificar estado
sleep 2

MANUFACTURER=$(sudo dmidecode -s system-manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')

echo
echo "═══════════════════════════════════════════════════════════"
if echo "$MANUFACTURER" | grep -qi "micro-star\|msi"; then
    echo -e "  ${GREEN}Laptop MSI detectada${NC}"
    echo "═══════════════════════════════════════════════════════════"
    echo
    if systemctl is-active --quiet msi-ec-custom.service; then
        echo -e "${GREEN}✓ msi-ec-custom.service activo${NC}"
    else
        echo -e "${YELLOW}⚠ msi-ec-custom.service inactivo${NC}"
    fi
    
    if systemctl is-active --quiet msi-fan-daemon.service; then
        echo -e "${GREEN}✓ msi-fan-daemon.service activo${NC}"
    else
        echo -e "${YELLOW}⚠ msi-fan-daemon.service inactivo${NC}"
    fi
    
    echo
    echo "Prueba: msi-fan"
else
    echo -e "  ${BLUE}Laptop no-MSI detectada ($MANUFACTURER)${NC}"
    echo "═══════════════════════════════════════════════════════════"
    echo
    echo -e "${GREEN}✓ Servicios configurados correctamente${NC}"
    echo "  Los servicios MSI se saltarán automáticamente"
    echo "  en esta laptop."
fi

echo
echo -e "${BLUE}Comportamiento:${NC}"
echo "  • En MSI Vector → Control de ventiladores activo"
echo "  • En Dell Latitude → Servicios se saltan sin errores"
echo "  • Mismo Ubuntu funciona en ambas laptops"
echo
