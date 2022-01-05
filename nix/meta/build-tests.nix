{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  allRoots = [

    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)
  
    dev.icecap.sel4-manual

    musl.icecap.icecap-host
    musl.icecap.firecracker
    musl.icecap.firecracker-prebuilt
    musl.icecap.firectl

    (lib.flip lib.concatMap [ dev linux ] (host: [
      host.icecap.crosvm-9p-server
    ]))

    (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (_: configured: [
      configured.sysroot-rs
    ]))

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      meta.tests.realm-vm
      meta.tests.analysis
      meta.tests.benchmark-utilisation
    ])

    meta.tests.firecracker.rpi4.boot

  ];

in {

  all = pkgs.dev.writeText "build-test-roots" (toString (lib.flatten allRoots));

}
