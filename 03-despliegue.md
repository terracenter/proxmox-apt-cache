# 03 — Desplegar el Contenedor

## 3.1 Preparar el directorio de trabajo

> El repositorio `proxmox-apt-cache` es el proyecto público que contiene los archivos Docker de este manual. Está publicado separadamente en GitHub para facilitar el despliegue en cualquier nodo.

```bash
# 1. Clonar el repositorio del proyecto
git clone https://github.com/terracenter/proxmox-apt-cache.git
cd proxmox-apt-cache

# 2. Crear directorio de despliegue y copiar archivos de configuración
sudo mkdir -p /opt/apt-cache
sudo cp -rv docker/* /opt/apt-cache/
```

## 3.2 Configurar el .env

```bash
echo 'CACHE_PATH=/mnt/apt-cache' | sudo tee /opt/apt-cache/.env
```

## 3.3 🚨 SEGURIDAD OBLIGATORIA: Configuración de Firewall (UFW)

Es **CRÍTICO** que el firewall `ufw` esté activo para proteger el puerto `3142`. El acceso debe restringirse únicamente a la red local del nodo:

```bash
# 0. ASEGURAR QUE UFW ESTÁ ACTIVO
sudo ufw enable

# 1. Identificar dinámicamente el segmento de red de vmbr0
VMBR0_NET=$(ip r show dev vmbr0 | grep "proto kernel" | grep -v "default" | awk '{print $1}')

# 2. Permitir tráfico al puerto 3142 solo desde esa red
sudo ufw allow from $VMBR0_NET to any port 3142 proto tcp comment 'APT Proxy desde vmbr0'

# 3. Verificar la regla y el estado
sudo ufw status verbose
```

## 3.4 Configurar credenciales del panel de administración

Antes de construir la imagen, establecer la contraseña para `/acng-report.html`.
Editar `docker/apt-cacher-ng/acng.conf` y cambiar la línea `AdminAuth`:

```bash
sudo vim /opt/apt-cache/apt-cacher-ng/acng.conf
```

Buscar y reemplazar:
```
AdminAuth: admin:CAMBIAR_ESTA_CLAVE
```

Por:
```
AdminAuth: admin:tu_contraseña_segura
```

> La contraseña protege solo la interfaz web de reportes y administración.
> Las descargas de paquetes (`apt update`, `apt install`) **no requieren** autenticación.

## 3.5 Construir y desplegar

```bash
cd /opt/apt-cache
sudo docker compose up -d --build
```

## 3.6 Verificar estado

```bash
sudo docker compose ps
sudo docker exec apt-cacher-ng ip addr
sudo docker exec apt-cacher-ng pgrep -a unbound
```

## 3.7 Probar conectividad local

```bash
curl -s http://192.168.3.2:3142 | head -5
```

---
[⬅️ Anterior](02-docker-proxmox.md) | [🏠 Inicio](../../README.md) | [Siguiente ➡️](04-clientes.md) | [📚 Manuales](../../README.md)
