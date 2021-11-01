{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  allRoots = lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (k: _: [
    meta.demos.minimal.${k}.run
    meta.demos.minimal-root.${k}.run
    meta.demos.realm-vm.${k}.run
    meta.tests.realm-vm.${k}.run
    meta.tests.analysis.${k}.run
    meta.tests.benchmark-utilisation.${k}.run
  ] ++ lib.optionals dev.hostPlatform.isx86_64 [
    meta.demos.realm-mirage.${k}.run
  ]) ++ lib.flip lib.concatMap [ dev linux ] (host: [
    host.icecap.crosvm-9p-server
  ]) ++ [
    dev.icecap.sel4-manual
    meta.tests.firecracker.rpi4.boot
    musl.icecap.icecap-host
    musl.icecap.firecracker
    musl.icecap.firecracker-prebuilt
    musl.icecap.firectl
  ];

in {

  all = pkgs.dev.writeText "build-test-roots" (toString (lib.flatten allRoots));

}
