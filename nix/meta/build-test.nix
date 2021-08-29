{ lib, pkgs, instances }:

let
  inherit (pkgs) dev linux none;
  inherit (none.icecap) icecapPlats;
in
  lib.concatMap (plat: [
    instances.${plat}.test.realm-vm.run
    instances.${plat}.demos.minimal.run
    instances.${plat}.demos.minimal-root.run
    instances.${plat}.demos.realm-vm.run
    instances.${plat}.demos.mirage.run
    # pkgs.none.icecap.configured.${plat}.sysroot-rs # broken (must update for rust bump)
  ]) icecapPlats ++ lib.concatMap (host: [
    host.icecap._9p-server
  ]) [ dev linux ] ++ [
    dev.icecap.sel4-manual
    instances.rpi4.test.firecracker.boot
  ]
