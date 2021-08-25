{ pkgs, configured, instances }:

let
  inherit (pkgs) lib dev linux none;
  inherit (none.icecap) icecapPlats;
in
  lib.concatMap (plat: [
    instances.${plat}.test.realm-vm.run
    instances.${plat}.test.host-2-stage.run
    instances.${plat}.demos.minimal.run
    instances.${plat}.demos.minimal-root.run
    instances.${plat}.demos.realm-vm.run
    instances.${plat}.demos.mirage.run
    configured.${plat}.sysroot-rs
  ]) icecapPlats ++ lib.concatMap (host: [
    host.icecap._9p-server
  ]) [ dev linux ] ++ [
    dev.icecap.sel4-manual
  ]
