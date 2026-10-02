#!/bin/bash
# =====================================================================
# kali_preparar_servidores_dmz.sh - P3 Infraestructura 1
# Jose Gabriel Feliz Maria - 2025-0742
#
# El Kali (conectado a la DMZ por VMnet2 / Cloud1) es el HOST DE
# CONTENEDORES. Este script crea los 3 servidores de la DMZ como
# contenedores Docker, cada uno con su propia IP y MAC en la red DMZ
# (driver macvlan sobre eth1):
#   web-caja        10.7.43.2  Web Server: Sistema de Caja (nginx + SSH)
#   web-inventario  10.7.43.3  Web Server: Sistema de Inventario (nginx + SSH)
#   db-server       10.7.43.4  DB Server (MariaDB + SSH)
# Gateway y DNS de la DMZ: 10.7.43.1 (port3 del FortiGate).
#
# Uso: sudo bash kali_preparar_servidores_dmz.sh
# (las imagenes se descargan a traves del FortiGate: politica DMZ -> Internet)
# =====================================================================
set -e

if [ "$(id -u)" -ne 0 ]; then echo "Ejecuta con: sudo bash $0"; exit 1; fi

BASE=/opt/dmz0742
PARENT=eth1                 # interfaz del Kali conectada a VMnet2 (DMZ)
SUBNET=10.7.43.0/28
GATEWAY=10.7.43.1

read -s -p "Contrasena para el usuario 'admin' de los servidores (SSH y BD): " ADMIN_PASS; echo
[ -z "$ADMIN_PASS" ] && { echo "La contrasena no puede estar vacia"; exit 1; }

mkdir -p $BASE/web $BASE/db $BASE/caja $BASE/inventario

# ---------- Imagen de los Web Servers (Debian + nginx + SSH) ----------
cat > $BASE/web/Dockerfile <<'EOF'
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx openssh-server curl iputils-ping iproute2 ca-certificates \
 && mkdir -p /run/sshd
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 80 22
CMD ["/start.sh"]
EOF

cat > $BASE/web/start.sh <<'EOF'
#!/bin/bash
id admin >/dev/null 2>&1 || useradd -m -s /bin/bash admin
echo "admin:${ADMIN_PASS}" | chpasswd
/usr/sbin/sshd
exec nginx -g 'daemon off;'
EOF

# ---------- Imagen del DB Server (Debian + MariaDB + SSH) ----------
cat > $BASE/db/Dockerfile <<'EOF'
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server openssh-server curl iputils-ping iproute2 ca-certificates \
 && mkdir -p /run/sshd /run/mysqld && chown mysql:mysql /run/mysqld
COPY init.sql /init.sql
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 3306 22
CMD ["/start.sh"]
EOF

cat > $BASE/db/init.sql <<'EOF'
CREATE DATABASE IF NOT EXISTS empresa_0742;
USE empresa_0742;
CREATE TABLE IF NOT EXISTS productos (
  id INT PRIMARY KEY, nombre VARCHAR(60), existencia INT, precio DECIMAL(10,2));
CREATE TABLE IF NOT EXISTS ventas (
  id INT AUTO_INCREMENT PRIMARY KEY, producto_id INT, cantidad INT,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP);
INSERT IGNORE INTO productos VALUES
  (1,'Router Cisco ISR',10,850.00),(2,'Switch 24 puertos',25,320.00),
  (3,'Cable UTP Cat6 (caja)',40,95.50),(4,'FortiGate 40F',5,1200.00);
EOF

cat > $BASE/db/start.sh <<'EOF'
#!/bin/bash
id admin >/dev/null 2>&1 || useradd -m -s /bin/bash admin
echo "admin:${ADMIN_PASS}" | chpasswd
/usr/sbin/sshd
mysqld_safe --bind-address=0.0.0.0 &
for i in $(seq 1 30); do mysqladmin ping --silent && break; sleep 1; done
mysql < /init.sql
mysql -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY '${ADMIN_PASS}'; GRANT SELECT, INSERT ON empresa_0742.* TO 'admin'@'%'; FLUSH PRIVILEGES;"
wait
EOF

# ---------- Paginas web ----------
pagina() {  # $1 titulo  $2 ip  $3 color  $4 descripcion
cat <<EOF
<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><title>$1</title>
<style>
body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#0f172a;color:#e2e8f0}
header{background:$3;padding:28px 40px}
h1{margin:0;font-size:34px} main{padding:30px 40px}
.card{background:#1e293b;border-radius:10px;padding:18px 22px;margin:14px 0;max-width:720px}
td,th{padding:6px 14px;text-align:left} small{color:#94a3b8}
</style></head><body>
<header><h1>$1</h1><div>$4</div></header>
<main>
<div class="card"><b>Servidor:</b> $2 &nbsp;|&nbsp; <b>Zona:</b> DMZ 10.7.43.0/28 &nbsp;|&nbsp; <b>Gateway:</b> FortiGate 10.7.43.1</div>
<div class="card"><table><tr><th>Producto</th><th>Existencia</th><th>Precio</th></tr>
<tr><td>Router Cisco ISR</td><td>10</td><td>RD\$ 850.00</td></tr>
<tr><td>Switch 24 puertos</td><td>25</td><td>RD\$ 320.00</td></tr>
<tr><td>FortiGate 40F</td><td>5</td><td>RD\$ 1,200.00</td></tr></table></div>
<small>Jose Gabriel Feliz Maria - Matricula 2025-0742 - Seguridad de Redes (ITLA) - P3 Infraestructura 1</small>
</main></body></html>
EOF
}
pagina "Sistema de Caja" "web-caja 10.7.43.2" "#15803d" "Punto de venta y facturacion" > $BASE/caja/index.html
pagina "Sistema de Inventario" "web-inventario 10.7.43.3" "#b45309" "Control de existencias del almacen" > $BASE/inventario/index.html

# ---------- Red DMZ (macvlan) y contenedores ----------
ip link set $PARENT promisc on
docker network inspect dmz_net >/dev/null 2>&1 || \
  docker network create -d macvlan --subnet $SUBNET --gateway $GATEWAY -o parent=$PARENT dmz_net

docker build -t srv-web-0742 $BASE/web
docker build -t srv-db-0742  $BASE/db

for c in web-caja web-inventario db-server; do docker rm -f $c >/dev/null 2>&1 || true; done

docker run -d --name web-caja --hostname web-caja --network dmz_net --ip 10.7.43.2 \
  --dns $GATEWAY --restart unless-stopped -e ADMIN_PASS="$ADMIN_PASS" \
  -v $BASE/caja/index.html:/var/www/html/index.html:ro srv-web-0742

docker run -d --name web-inventario --hostname web-inventario --network dmz_net --ip 10.7.43.3 \
  --dns $GATEWAY --restart unless-stopped -e ADMIN_PASS="$ADMIN_PASS" \
  -v $BASE/inventario/index.html:/var/www/html/index.html:ro srv-web-0742

docker run -d --name db-server --hostname db-server --network dmz_net --ip 10.7.43.4 \
  --dns $GATEWAY --restart unless-stopped -e ADMIN_PASS="$ADMIN_PASS" srv-db-0742

echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
echo
echo "Listo. Servidores: web-caja 10.7.43.2 | web-inventario 10.7.43.3 | db-server 10.7.43.4"
