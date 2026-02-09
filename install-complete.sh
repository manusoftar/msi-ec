#!/bin/bash

# Instalador completo: Control automático de ventiladores MSI
# Incluye daemon en segundo plano + herramientas manuales

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════"
echo "  Instalación Completa - Control de Ventiladores MSI"
echo "  Vector GP68HX 12VH - Con daemon automático"
echo "═══════════════════════════════════════════════════════════"
echo

# 1. Verificar módulo compilado
if [ ! -f ~/Git/msi-ec/msi-ec.ko ]; then
    echo -e "${RED}ERROR: No se encuentra ~/Git/msi-ec/msi-ec.ko${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Módulo compilado encontrado${NC}"

# 2. Blacklistear módulo del kernel
echo
echo "Paso 1: Configurando módulo del kernel..."
echo "blacklist msi-ec" | sudo tee /etc/modprobe.d/blacklist-msi-ec.conf > /dev/null
echo -e "${GREEN}✓ Módulo del kernel blacklisteado${NC}"

# 3. Instalar servicio de carga del módulo
echo
echo "Paso 2: Instalando servicio de carga del módulo..."
sudo cp msi-ec-custom.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable msi-ec-custom.service
echo -e "${GREEN}✓ Servicio de módulo instalado${NC}"

# 4. Instalar daemon de control automático
echo
echo "Paso 3: Instalando daemon de control automático..."
sudo cp msi-fan-daemon.sh /usr/local/bin/msi-fan-daemon
sudo chmod +x /usr/local/bin/msi-fan-daemon
sudo cp msi-fan-daemon.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable msi-fan-daemon.service
echo -e "${GREEN}✓ Daemon automático instalado${NC}"

# 5. Instalar script de control manual
echo
echo "Paso 4: Instalando herramienta de control manual..."
sudo cp msi-fan-control.sh /usr/local/bin/msi-fan
sudo chmod +x /usr/local/bin/msi-fan
echo -e "${GREEN}✓ Comando 'msi-fan' instalado${NC}"

# 6. Cargar módulo ahora
echo
echo "Paso 5: Cargando módulo personalizado..."
sudo modprobe -r msi-ec 2>/dev/null || true
sudo rmmod msi_ec 2>/dev/null || true
sudo insmod ~/Git/msi-ec/msi-ec.ko

if ! lsmod | grep -q msi_ec; then
    echo -e "${RED}✗ Error al cargar módulo${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Módulo cargado${NC}"

# 7. Iniciar daemon
echo
echo "Paso 6: Iniciando daemon de control automático..."
sudo systemctl start msi-fan-daemon.service

# Esperar un momento para que el daemon se estabilice
sleep 2

# Verificar estado del daemon
if systemctl is-active --quiet msi-fan-daemon.service; then
    echo -e "${GREEN}✓ Daemon ejecutándose correctamente${NC}"
else
    echo -e "${YELLOW}⚠ Daemon no está activo, verificando...${NC}"
    sudo systemctl status msi-fan-daemon.service --no-pager
fi

# 8. Verificar controles
if [ ! -d /sys/devices/platform/msi-ec ]; then
    echo -e "${RED}✗ No se crearon los controles${NC}"
    exit 1
fi

echo
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${GREEN}INSTALACIÓN COMPLETA Y EXITOSA${NC}"
echo "═══════════════════════════════════════════════════════════"
echo
echo -e "${BLUE}Control automático en segundo plano:${NC}"
echo "  • El daemon ajusta los ventiladores automáticamente"
echo "  • Umbrales: >80°C=advanced, >70°C=auto, <60°C=silent"
echo "  • Se inicia automáticamente al arrancar el sistema"
echo
echo -e "${BLUE}Comandos disponibles:${NC}"
echo "  msi-fan               - Ver estado actual"
echo "  msi-fan monitor       - Monitoreo en tiempo real"
echo "  msi-fan advanced      - Forzar modo rendimiento"
echo "  msi-fan auto          - Forzar modo automático"
echo "  msi-fan silent        - Forzar modo silencioso"
echo "  msi-fan boost         - Toggle Cooler Boost"
echo
echo -e "${BLUE}Gestión del daemon:${NC}"
echo "  sudo systemctl status msi-fan-daemon    - Ver estado"
echo "  sudo systemctl stop msi-fan-daemon      - Detener (control manual)"
echo "  sudo systemctl start msi-fan-daemon     - Iniciar"
echo "  sudo journalctl -u msi-fan-daemon -f    - Ver log en vivo"
echo
echo -e "${YELLOW}Nota:${NC} El daemon controla automáticamente los ventiladores."
echo "Si quieres control manual, detén el daemon primero:"
echo "  sudo systemctl stop msi-fan-daemon"
echo
echo "Prueba ahora con: msi-fan"
echo
