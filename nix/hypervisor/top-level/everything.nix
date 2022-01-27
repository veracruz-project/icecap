{ lib, pkgs, framework, tcbSize, instances, automatedTests }:

let
  inherit (pkgs) dev none linux musl;

  forEachIn = lib.flip lib.concatMap;
  forEachConfigured = f: lib.mapAttrsToList (lib.const f) pkgs.none.icecap.configured;

in framework.mkEverything {

  cached = [
    (forEachConfigured (configured: [
      configured.icecapFirmware.display
    ]))

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      instances.tests.hypervisor
      instances.tests.benchmark-server
      instances.benchmarks.hypervisor
      instances.benchmarks.hypervisor-with-utilization
      instances.benchmarks.firecracker
    ])

    automatedTests.runAll

    tcbSize
  ];

  extraPure = [
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
}
