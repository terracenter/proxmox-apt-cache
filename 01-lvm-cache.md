# 01 — Crear Volumen LVM para el Caché

El caché de paquetes se almacena en un volumen LVM dedicado dentro del VG de Proxmox.

## 1.1 Identificar el tipo de LVM

**Paso 1 — ver los VGs disponibles:**

```bash
sudo vgs
```

**Paso 2 — revisar los LVs para detectar el thin pool:**

```bash
sudo lvs
```

### Verificar espacio disponible dentro del thin pool

```bash
sudo lvs
```

---

## 1.2 Crear el Logical Volume

### Opción A — LVM estándar

```bash
sudo lvcreate -L 20G -n apt-cache pve
```

Verificar:
```bash
sudo lvs | grep apt-cache
```

### Opción B — LVM-Thin

```bash
sudo lvcreate -V 20G -T lvm-data/data -n apt-cache
```

Verificar:
```bash
sudo lvs | grep apt-cache
```

---

## 1.3 Formatear como ext4

```bash
sudo mkfs.ext4 -L apt-cache /dev/lvm-data/apt-cache
```

---

## 1.4 Crear punto de montaje

```bash
sudo mkdir -p /mnt/apt-cache
```

---

## 1.5 Configurar montaje automático en fstab

```bash
echo '/dev/lvm-data/apt-cache /mnt/apt-cache ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab
```

---

## 1.6 Montar y verificar

```bash
sudo systemctl daemon-reload && sudo mount -a && df -h /mnt/apt-cache
```

---

## 1.7 Ajustar permisos

El servicio `apt-cacher-ng` dentro del contenedor Docker se ejecuta con un usuario interno que tiene el **UID 104** y el **GID 109**. Para que el contenedor pueda escribir en el volumen LVM, debemos asignar estos permisos en el host:

```bash
sudo chown -R 104:109 /mnt/apt-cache
```

> **Nota:** Si usas una imagen Docker diferente a la oficial de `sameersbn`, estos IDs podrían variar. Verifica con: `docker run --rm <imagen> id apt-cacher-ng`.

---

## Expandir el volumen en el futuro

### LVM estándar
```bash
sudo lvextend -L +20G /dev/pve/apt-cache && sudo resize2fs /dev/pve/apt-cache
```

### LVM-Thin
```bash
sudo lvextend -L +20G /dev/lvm-data/apt-cache && sudo resize2fs /dev/lvm-data/apt-cache
sudo lvextend -L +100G lvm-data/data
```

---
[⬅️ Anterior](README.md) | [🏠 Inicio](index.md) | [Siguiente ➡️](02-docker-proxmox.md) | [📚 Manuales](../index.md)
