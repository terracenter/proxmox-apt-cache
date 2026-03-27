# Índice — Caché de Paquetes APT con Docker en Proxmox

## Documentación del Proyecto

| # | Documento | Descripción |
|---|-----------|-------------|
| 0 | [README.md](README.md) | Arquitectura, diseño de red y visión general |
| 1 | [01-lvm-cache.md](01-lvm-cache.md) | Crear volumen LVM dedicado para el caché en Proxmox |
| 2 | [02-docker-proxmox.md](02-docker-proxmox.md) | Instalar Docker CE en el Proxmox host |
| 3 | [03-despliegue.md](03-despliegue.md) | Configurar `.env`, levantar contenedor y Firewall UFW |
| 4 | [04-clientes.md](04-clientes.md) | Configurar Proxmox host y VMs para usar el caché |

## Archivos de Configuración

| Archivo | Descripción |
|---------|-------------|
| [docker/docker-compose.yml](docker/docker-compose.yml) | Compose con red bridge `/30` + port mapping `:3142` |
| [docker/.env.ejemplo](docker/.env.ejemplo) | Ruta del caché LVM |

## Requisitos

- Proxmox VE 7.x / 8.x
- 20 GB+ libres en el VG `pve`
- Firewall UFW activo (Configuración de acceso incluida en el paso 03)

---

[🏠 Inicio](../../README.md) | [Siguiente ➡️](README.md) | [📚 Manuales](../../README.md)
