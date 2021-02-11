#!/bin/sh

set -e

gc() {
    pattern="$1"
    find  /nix/store/ -mindepth 1 -maxdepth 1 -name "$pattern" -exec nix-store --delete {} \;
}

gc '*sel4-elfloader-aarch64-none-elf'
gc '*-capdl-loader-aarch64-none-elf'
gc '*-manifest'
gc '*initrd.gz'
# TODO more

rm -r /tmp/nix-build-*
