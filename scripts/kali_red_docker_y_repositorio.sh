#!/bin/bash
# =====================================================================
# kali_red_docker_y_repositorio.sh - P3 Infraestructura 1
# Jose Gabriel Feliz Maria - 2025-0742
# Prepara el Kali como host de contenedores de la DMZ:
#   1. IP fija en eth1 (VMnet2 / Cloud1): 10.7.43.10/28, gateway y DNS
#      10.7.43.1 (port3 del FortiGate). accept-all-mac-addresses permite
#      que eth1 reciba el trafico de los contenedores (macvlan).
#   2. Repositorio fijo kali.download (un solo destino que el FortiGate
#      puede permitir por FQDN; http.kali.org redirige a espejos distintos).
#   3. Instala Docker y apaga el Apache del host (los web servers son
#      contenedores).
# Despues se ejecuta kali_preparar_servidores_dmz.sh
# =====================================================================
C=$(nmcli -t -f NAME,DEVICE con show | awk -F: '$2=="eth1"{print $1}'); echo "Conexion de eth1: $C"
sudo nmcli con mod "$C" ipv4.method manual ipv4.addresses 10.7.43.10/28 ipv4.gateway 10.7.43.1 ipv4.dns 10.7.43.1 ipv4.route-metric 500 ipv4.dns-priority 200
sudo nmcli con mod "$C" ethernet.accept-all-mac-addresses yes
sudo nmcli con up "$C"

echo "deb http://kali.download/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo systemctl disable --now apache2
