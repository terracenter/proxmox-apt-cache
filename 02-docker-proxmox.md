# 02 — Instalar Docker en Proxmox

## 2.1 Eliminar paquetes conflictivos

Verificar:
```bash
sudo dpkg -l | grep -E "docker|containerd|runc"
```

Eliminar:
```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt remove -y $pkg
done
```

## 2.2 Agregar el repositorio oficial de Docker

```bash
sudo apt update && sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

## 2.3 Instalar Docker CE y el plugin Compose

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 2.4 Verificar la instalación

```bash
sudo docker --version
sudo docker compose version
```

## 2.5 Verificar que Docker funciona

```bash
sudo docker run --rm hello-world
```

## 2.6 Configurar daemon.json

> **Por qué se deshabilita `docker0`:** La red bridge por defecto de Docker usa `172.17.0.0/16`, un rango que frecuentemente entra en conflicto con redes de servidores en producción. Deshabilitar `docker0` y definir redes explícitas en cada `docker-compose.yml` elimina ese conflicto y da control total sobre el direccionamiento.

> ⚠️ **Si ya tienes otros contenedores corriendo en este host:** Al deshabilitar `docker0`, perderán conectividad si dependen de la red por defecto. Antes de aplicar este cambio, verifica que cada `docker-compose.yml` existente defina su propia red con `driver: bridge`. Casi ningún despliegue de producción usa la red por defecto, pero es necesario confirmarlo.

```bash
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "bridge": "none",
  "iptables": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

Verificar que docker0 ya no existe:
```bash
sudo ip -br a | grep docker
# Sin salida = correcto. docker0 eliminado.
```

## 2.7 Habilitar Docker en el arranque

```bash
sudo systemctl enable docker
sudo systemctl status docker
```

---
[⬅️ Anterior](01-lvm-cache.md) | [🏠 Inicio](../../README.md) | [Siguiente ➡️](03-despliegue.md) | [📚 Manuales](../../README.md)
