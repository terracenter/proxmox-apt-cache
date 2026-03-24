# 04 — Configurar Clientes

Una vez el contenedor está corriendo, hay que apuntar cada cliente (el propio host Proxmox y sus VMs) al proxy.

> **REQUISITO:** UFW debe estar activo y la regla del puerto `3142` debe estar aplicada antes de configurar los clientes. Ver paso [3.3 del despliegue](03-despliegue.md#33--seguridad-obligatoria-configuración-de-firewall-ufw) y la [Guía de Firewall](../../Seguridad/01.Firewall.md).

---

## 4.1 Configurar el Proxmox Host

El host se conecta al contenedor directamente por la red bridge interna (`192.168.3.2`), sin pasar por el port mapping:

```bash
sudo tee /etc/apt/apt.conf.d/01proxy << 'EOF'
Acquire::http::Proxy "http://192.168.3.2:3142";
Acquire::https::Proxy "DIRECT";
EOF

sudo apt update
```

> La IP `192.168.3.2` es la dirección del contenedor en el bridge interno del host. Solo es accesible desde el propio Proxmox host, no desde las VMs.

---

## 4.2 Configurar las VMs

Las VMs no tienen acceso al bridge interno. Se conectan al proxy usando la IP de `vmbr0` del host Proxmox más el port mapping `:3142`.

**Ejecutar en el host Proxmox** para obtener la IP y generar el bloque de configuración listo para copiar en cada VM:

```bash
# Detectar la IP de vmbr0 del host
# Ejemplo de salida de ip -br a:  vmbr0  UP  172.16.9.8/24
VMBR0_IP=$(ip -br a show dev vmbr0 | awk '{print $3}' | cut -d'/' -f1)
echo "Acquire::http::Proxy \"http://${VMBR0_IP}:3142\";"
```

Salida esperada (copiar el valor resultante):
```
Acquire::http::Proxy "http://172.16.9.8:3142";
```

**Ejecutar en cada VM** (sustituir la IP por la del host de su nodo):

```bash
VMBR0_IP="172.16.9.8"   # ← IP obtenida del paso anterior
sudo tee /etc/apt/apt.conf.d/01proxy << EOF
Acquire::http::Proxy "http://${VMBR0_IP}:3142";
Acquire::https::Proxy "DIRECT";
EOF

sudo apt update
```

> Cada nodo Proxmox tiene su propia instancia del proxy. Las VMs de un nodo usan la IP de **su** host, no la de otro nodo.

---

## 4.3 Verificar que el caché está siendo usado

### Prueba de descarga con cache hit

Descargar el mismo paquete dos veces. La segunda debe ser instantánea:

```bash
sudo apt install -d curl   # descarga sin instalar
sudo apt install -d curl   # debe decir "ya descargado" o ser inmediata
```

### Ver archivos almacenados en el LVM

```bash
sudo ls /mnt/apt-cache/
```

Salida esperada (archivos `.deb` y metadatos de repos):
```
_acng_submit_info/  deb.debian.org/  security.debian.org/
```

### Panel de estadísticas web

`apt-cacher-ng` incluye un panel de administración accesible desde el host:

```bash
curl -s http://192.168.3.2:3142/acng-report.html | grep -E "hit|miss|bytes"
```

O abrir en un navegador desde la red local:
```
http://<IP_HOST>:3142/acng-report.html
```

### Logs en tiempo real

```bash
sudo docker compose -f /opt/apt-cache/docker-compose.yml logs -f
```

---

## 4.4 Quitar la configuración del proxy

Útil en troubleshooting para descartar el proxy como causa de un problema:

```bash
# Deshabilitar temporalmente (renombrar el archivo)
sudo mv /etc/apt/apt.conf.d/01proxy /etc/apt/apt.conf.d/01proxy.disabled

# Verificar que apt ya no usa el proxy
sudo apt update

# Reactivar cuando se resuelva el problema
sudo mv /etc/apt/apt.conf.d/01proxy.disabled /etc/apt/apt.conf.d/01proxy
```

---

[⬅️ Anterior](03-despliegue.md) | [🏠 Inicio](index.md) | [📚 Manuales](../index.md)
