{ lib, pkgs, meta }:

let
  inherit (pkgs) dev linux none;
  inherit (none.icecap) icecapPlats;
in
  lib.concatLists (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (k: _: [
    meta.demos.minimal.${k}.run
    meta.demos.minimal-root.${k}.run
    meta.demos.realm-mirage.${k}.run
    meta.demos.realm-vm.${k}.run
  ])) ++ lib.concatMap (plat: [
    meta.instances.${plat}.test.realm-vm.run
    # pkgs.none.icecap.configured.${plat}.sysroot-rs # broken (must update for rust bump)
  ]) icecapPlats ++ lib.concatMap (host: [
    host.icecap._9p-server
  ]) [ dev linux ] ++ [
    dev.icecap.sel4-manual
    meta.instances.rpi4.test.firecracker.boot
  ]
