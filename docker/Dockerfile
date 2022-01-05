FROM debian:bullseye-slim

ARG UID
ARG GID

RUN apt-get update && apt-get install -y \
    curl git make \
    man rsync procps \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -f -g $GID x && useradd -u $UID -g $GID -m -p x x

RUN mkdir -m 0755 /nix && chown x:x /nix
VOLUME /nix

USER x

ENV PATH="/nix/env/bin:${PATH}"
ENV MANPATH="/nix/env/share/man:${MANPATH}"
ENV NIX_SSL_CERT_FILE=/nix/env/etc/ssl/certs/ca-bundle.crt

# HACK for persistent git cache
ENV XDG_CACHE_HOME=/nix/cache

COPY nix.conf /etc/nix/
COPY install-nix.sh /
COPY setup.sh /

WORKDIR /icecap
