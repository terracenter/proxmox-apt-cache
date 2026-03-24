# Caché de Paquetes APT con Docker en Proxmox

## Problema

Cada nodo Proxmox es independiente (sin cluster) y está detrás de NAT. Cuando las VMs
y el propio Proxmox actualizan paquetes, cada uno descarga lo mismo de internet.
Si hay 10 VMs con Debian y sale una actualización de `openssl`, se descarga 10 veces.

## Solución

Un contenedor Docker con `apt-cacher-ng` corriendo **directamente en cada Proxmox host**,
con caché persistente en un volumen LVM. La imagen se construye desde `debian:stable-slim`
con un `Dockerfile` — no se usan imágenes de terceros.

## Arquitectura de Red por Nodo

```mermaid
graph TB
    subgraph INTERNET["Internet"]
        REPO[(Repositorios<br>deb.debian.org<br>security.debian.org<br>download.proxmox.com)]
    end

    subgraph PVE["Proxmox Host"]
        HOST["Proxmox Host<br><code>vmbr0: IP_DEL_NODO</code>"]

        subgraph DOCKER["Docker"]
            ACN["apt-cacher-ng + unbound<br><code>host_bridge: 192.168.3.2</code><br><code>port mapping :3142</code>"]
            LVM[("LVM<br>/mnt/apt-cache")]
        end
    end

    subgraph VMS["VMs del Nodo (vmbr0)"]
        VM1["VM-1"]
        VM2["VM-2"]
        VMN["VM-N"]
    end

    HOST -- "host_bridge<br>192.168.3.2:3142" --> ACN
    ACN --- LVM
    ACN -- "NAT" --> REPO

    VM1 -- "port mapping<br>IP_HOST:3142" --> ACN
    VM2 -- "port mapping<br>IP_HOST:3142" --> ACN
    VMN -- "port mapping<br>IP_HOST:3142" --> ACN

    style DOCKER fill:#2d3748,stroke:#4a5568,color:#e2e8f0
    style PVE fill:#1a202c,stroke:#2d3748,color:#e2e8f0
    style VMS fill:#1c3d5a,stroke:#2b6cb0,color:#e2e8f0
    style INTERNET fill:#2f4f2f,stroke:#48bb78,color:#e2e8f0
    style REPO fill:#276749,stroke:#48bb78,color:#e2e8f0
    style ACN fill:#c53030,stroke:#fc8181,color:#fff
    style LVM fill:#b7791f,stroke:#ecc94b,color:#fff
    style HOST fill:#553c9a,stroke:#9f7aea,color:#fff
    style VM1 fill:#2b6cb0,stroke:#63b3ed,color:#fff
    style VM2 fill:#2b6cb0,stroke:#63b3ed,color:#fff
    style VMN fill:#2b6cb0,stroke:#63b3ed,color:#fff
```

### Flujo de red

```mermaid
flowchart LR
    subgraph RED_BRIDGE["host_bridge (192.168.3.0/30) — Solo Host"]
        direction LR
        GW["Host<br>192.168.3.1"] --> ACNB["apt-cacher-ng<br>192.168.3.2"]
    end

    subgraph RED_PORT["Port Mapping (:3142) — VMs"]
        direction LR
        VM_A["VM-1"] --> ACNP["IP_HOST:3142"]
        VM_B["VM-2"] --> ACNP
        VM_C["VM-N"] --> ACNP
    end

    style RED_BRIDGE fill:#1a202c,stroke:#9f7aea,color:#e2e8f0
    style RED_PORT fill:#1c3d5a,stroke:#63b3ed,color:#e2e8f0
```

**host_bridge (192.168.3.0/30):** Red bridge user-defined creada por docker-compose.
El host accede al contenedor via `192.168.3.2:3142`. `docker0` está deshabilitado
(`bridge: none` en `daemon.json`) — esta es la única red bridge del host.

**Port mapping (:3142):** Docker publica el puerto 3142 del contenedor en todas
las interfaces del host. Las VMs acceden al caché usando la IP del Proxmox host
(la misma IP de vmbr0). No requiere redes adicionales ni IPs extras.

**DNS:** FreeIPA es el DNS de todas las VMs y del Proxmox host.
Dentro del contenedor, `unbound` corre como DNS cache interno en `127.0.0.1`
para que `apt-cacher-ng` resuelva nombres de repositorios.

## Requisitos

- Proxmox VE 7.x o 8.x
- Espacio en el VG `pve` para un volumen LVM (mínimo 20 GB)
- Docker CE instalado en el Proxmox host
- FreeIPA configurado como DNS en las VMs

## Guía Paso a Paso

| Paso | Documento | Descripción |
|------|-----------|-------------|
| 1 | [01-lvm-cache.md](01-lvm-cache.md) | Crear volumen LVM para el caché |
| 2 | [02-docker-proxmox.md](02-docker-proxmox.md) | Instalar Docker en Proxmox |
| 3 | [03-despliegue.md](03-despliegue.md) | Desplegar el contenedor con docker-compose |
| 4 | [04-clientes.md](04-clientes.md) | Configurar VMs y Proxmox host como clientes |

## Archivos Docker

```mermaid
graph LR
    subgraph docker/
        DC[docker-compose.yml]
        ENV[.env.ejemplo]
        subgraph apt-cacher-ng/
            DF[Dockerfile]
            EP[entrypoint.sh]
            ACNG[acng.conf]
            UBC[unbound.conf]
        end
    end

    DC --> DF
    DC --> ENV

    style DC fill:#c53030,stroke:#fc8181,color:#fff
    style ENV fill:#b7791f,stroke:#ecc94b,color:#fff
    style DF fill:#553c9a,stroke:#9f7aea,color:#fff
    style EP fill:#553c9a,stroke:#9f7aea,color:#fff
    style ACNG fill:#2b6cb0,stroke:#63b3ed,color:#fff
    style UBC fill:#276749,stroke:#48bb78,color:#fff
```

## Ejemplo de IPs por Nodo

| Nodo | IP del Host (vmbr0) | IP proxy para las VMs | Bridge interno |
|------|--------------------|-----------------------|----------------|
| Nodo A | 10.0.1.1 | 10.0.1.1:3142 | 192.168.3.0/30 |
| Nodo B | 172.16.5.1 | 172.16.5.1:3142 | 192.168.3.0/30 |
| Nodo C | 10.10.0.1 | 10.10.0.1:3142 | 192.168.3.0/30 |

> Las VMs usan la IP del Proxmox host como proxy. No se necesitan IPs adicionales.
> La red bridge interna `192.168.3.0/30` es la misma en todos los nodos — es aislada.

```mermaid
graph TB
    subgraph NODO_A["Nodo A — 10.0.1.1"]
        HA["Proxmox Host A"] --> CA["apt-cacher-ng<br>:3142"]
        VA1["VM"] --> HA
        VA2["VM"] --> HA
    end

    subgraph NODO_B["Nodo B — 172.16.5.1"]
        HB["Proxmox Host B"] --> CB["apt-cacher-ng<br>:3142"]
        VB1["VM"] --> HB
    end

    subgraph NODO_C["Nodo C — 10.10.0.1"]
        HC["Proxmox Host C"] --> CC["apt-cacher-ng<br>:3142"]
        VC1["VM"] --> HC
        VC2["VM"] --> HC
        VC3["VM"] --> HC
    end

    CA -. "NAT" .-> INET((Internet))
    CB -. "NAT" .-> INET
    CC -. "NAT" .-> INET

    style NODO_A fill:#1a202c,stroke:#9f7aea,color:#e2e8f0
    style NODO_B fill:#1a202c,stroke:#63b3ed,color:#e2e8f0
    style NODO_C fill:#1a202c,stroke:#48bb78,color:#e2e8f0
    style CA fill:#c53030,stroke:#fc8181,color:#fff
    style CB fill:#c53030,stroke:#fc8181,color:#fff
    style CC fill:#c53030,stroke:#fc8181,color:#fff
    style INET fill:#2f4f2f,stroke:#48bb78,color:#e2e8f0
```

---
[🏠 Inicio](index.md) | [Siguiente ➡️](01-lvm-cache.md) | [📚 Manuales](../index.md)
