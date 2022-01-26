{ lib, pkgs, tcbSize, instances }:

let
  inherit (pkgs) dev none linux musl;

  forEachIn = lib.flip lib.concatMap;
  forEachConfigured = f: lib.mapAttrsToList (lib.const f) pkgs.none.icecap.configured;

  cached = [
    (forEachConfigured (configured: [
      configured.icecapFirmware.display
    ]))

    tcbSize

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      instances.tests.hypervisor
      instances.tests.benchmark-server
      instances.benchmarks.hypervisor
      instances.benchmarks.hypervisor-with-utilization
      instances.benchmarks.firecracker
    ])
  ];

  pure = [
    cached

    (forEachIn [ linux musl ] (host: [
      host.icecap.icecap-host
      host.icecap.firecracker
      host.icecap.firecracker-prebuilt
      host.icecap.firectl
    ]))

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      instances.hacking.example # NOTE okay to remove this during periods when it's broken
    ])
  ];

  impure = [
  ];

  all = [
    pure
  ];

  mk = name: drvs: pkgs.dev.writeText name (toString (lib.flatten drvs));

in {

  cached = mk "everything-cached" cached;
  pure = mk "everything-pure" pure;
  impure = mk "everything-impure" impure;
  all = mk "everything" all;

}
