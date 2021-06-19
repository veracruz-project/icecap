FROM debian:buster

ARG UID

RUN apt-get update && apt-get install -y \
    curl git \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -u $UID -m -p deadbeef -s /bin/bash x
USER x
WORKDIR /home/x

ENV PATH="/home/x/hack/nix/bin:/nix/env/bin:${PATH}"
ENV MANPATH="/home/x/hack/nix/share/man:/nix/env/share/man:${MANPATH}"
ENV NIX_SSL_CERT_FILE=/nix/env/etc/ssl/certs/ca-bundle.crt

# HACK for persistent git cache.
# TODO patch nix to use $NIX_CACHE_HACK instead.
ENV XDG_CACHE_HOME=/nix/cache

COPY nix.conf /etc/nix/
COPY entrypoint.sh .
ENTRYPOINT ["bash", "entrypoint.sh"]
