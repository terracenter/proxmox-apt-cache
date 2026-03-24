# 04 — Configurar Clientes

## 4.1 Configurar el Proxmox Host

```bash
sudo tee /etc/apt/apt.conf.d/01proxy << 'EOF'
Acquire::http::Proxy "http://192.168.3.2:3142";
Acquire::https::Proxy "DIRECT";
EOF

sudo apt update
```

## 4.2 Configurar las VMs

Reemplazar `<IP_HOST>` con la IP de vmbr0:

```bash
sudo tee /etc/apt/apt.conf.d/01proxy << 'EOF'
Acquire::http::Proxy "http://<IP_HOST>:3142";
Acquire::https::Proxy "DIRECT";
EOF

sudo apt update
```

## 4.3 Verificar funcionamiento

### Prueba: verificar archivos en el LVM

```bash
sudo ls /mnt/apt-cache/
```

### Logs en tiempo real

```bash
sudo docker compose -f /opt/apt-cache/docker-compose.yml logs -f
```

---
[⬅️ Anterior](03-despliegue.md) | [🏠 Inicio](index.md) | [📚 Manuales](../index.md)
