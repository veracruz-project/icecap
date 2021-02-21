let
  top = import ../nix;
  inherit (top) lib dev linux instances;
  inherit (top.none.icecap) icecapPlats;
in
  lib.concatMap (plat: [
    instances.${plat}.test.sel4test.run
    instances.${plat}.test.host.run
    instances.${plat}.test.host-and-adjacent-vm.run
    instances.${plat}.test.timer-and-serial.run
    instances.${plat}.test.timer-and-serial-from-realm.run
    instances.${plat}.demos.minimal.run
    instances.${plat}.demos.minimal-root.run
    instances.${plat}.demos.realm-vm.run
    instances.${plat}.demos.mirage.run
    instances.${plat}.bench.baseline.run
    instances.${plat}.bench.baseline.test
  ]) icecapPlats ++ lib.concatMap (host: [
    host.icecap._9p-server
  ]) [ dev linux ]
