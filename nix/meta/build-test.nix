{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;
  inherit (none.icecap) icecapPlats;
in
  lib.concatLists (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (k: _: [
    meta.demos.minimal.${k}.run
    meta.demos.minimal-root.${k}.run
    meta.demos.realm-mirage.${k}.run
    meta.demos.realm-vm.${k}.run
    meta.tests.realm-vm.${k}.run
  ])) ++ lib.concatMap (host: [
    host.icecap._9p-server
  ]) [ dev linux ] ++ [
    dev.icecap.sel4-manual
    meta.tests.firecracker.rpi4.boot
    musl.icecap.icecap-host
  ]
