FROM debian:buster

ARG UID
ARG GID

RUN apt-get update && apt-get install -y \
    curl git man make \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -f -g $GID x && useradd -u $UID -g $GID -m -p x x
USER x

ENV PATH="/home/x/hack/nix/bin:/nix/env/bin:${PATH}"
ENV MANPATH="/home/x/hack/nix/share/man:/nix/env/share/man:${MANPATH}"
ENV NIX_SSL_CERT_FILE=/nix/env/etc/ssl/certs/ca-bundle.crt

# HACK for persistent git cache.
# TODO patch nix to use $NIX_CACHE_HACK instead.
ENV XDG_CACHE_HOME=/nix/cache

COPY nix.conf /etc/nix/
COPY setup.sh /

WORKDIR /icecap
