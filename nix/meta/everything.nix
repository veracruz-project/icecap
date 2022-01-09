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
      realm-kernel
      host-tools
      build-tools
    ]))

    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)

    meta.tcbSize

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      meta.tests.hypervisor
      meta.tests.backtrace
      meta.tests.benchmark-server
      meta.benchmarks.hypervisor
      meta.benchmarks.firecracker
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
      meta.hacking.hypervisor # NOTE okay to remove this during periods when it's broken
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
