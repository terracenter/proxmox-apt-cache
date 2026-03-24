#!/bin/bash
set -e

# Asegurar permisos del directorio de caché
chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng

# Crear directorio del socket con permisos correctos
mkdir -p /run/apt-cacher-ng
chown apt-cacher-ng:apt-cacher-ng /run/apt-cacher-ng

# Iniciar unbound como daemon (DNS cache local para apt-cacher-ng)
unbound

# Iniciar apt-cacher-ng en foreground
exec /usr/sbin/apt-cacher-ng ForeGround=1
