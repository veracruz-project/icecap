{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  forEachIn = lib.flip lib.concatMap;
  forEachConfigured = f: lib.mapAttrsToList (lib.const f) pkgs.none.icecap.configured;

  cached = [
    (forEachConfigured (configured: [
      configured.icecapFirmware.display
    ]))

    (lib.flatten (with meta.display; [
      (lib.attrValues host-kernel)
      host-tools
      realm-kernel
      (lib.attrValues realm-libraries)
      build-tools
    ]))

    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)

    meta.tcbSize

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      meta.instances.tests.hypervisor
      meta.instances.tests.backtrace
      meta.instances.tests.benchmark-server
      meta.instances.benchmarks.hypervisor
      meta.instances.benchmarks.hypervisor-with-utilization
      meta.instances.benchmarks.firecracker
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

    (forEachIn [ dev linux musl ] (host: [
      host.icecap.crosvm-9p-server
    ]))

    (forEachIn [ dev ] (host: [
      dev.icecap.bindgen
    ]))

    (forEachConfigured (configured: [
      configured.sysroot-rs
    ]))

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      meta.instances.hacking.example # NOTE okay to remove this during periods when it's broken
    ])
  ];

  impure = [
    meta.adHocBuildTests.allList
    meta.generatedDocs.html
  ];

  all = [
    pure
    impure
  ];

  mk = name: drvs: pkgs.dev.writeText name (toString (lib.flatten drvs));

in {

  cached = mk "everything-cached" cached;
  pure = mk "everything-pure" pure;
  impure = mk "everything-impure" impure;
  all = mk "everything" all;

}
