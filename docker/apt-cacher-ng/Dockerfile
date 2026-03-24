FROM debian:stable-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-cacher-ng \
       unbound \
       curl \
       iproute2 \
       procps \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/apt-cacher-ng/zz_debconf.conf \
    && chown apt-cacher-ng:apt-cacher-ng /run/apt-cacher-ng

COPY acng.conf /etc/apt-cacher-ng/acng.conf
COPY unbound.conf /etc/unbound/unbound.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3142

ENTRYPOINT ["/entrypoint.sh"]
