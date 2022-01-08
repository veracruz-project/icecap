{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  cached = [
    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)

    (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (_: configured: [
      configured.icecapFirmware.display
      configured.sysroot-rs
    ]))

    (lib.flip lib.concatMap [ dev linux musl ] (host: [
      host.icecap.crosvm-9p-server
    ]))

    (lib.flip lib.concatMap [ linux musl ] (host: [
      host.icecap.icecap-host
      host.icecap.firecracker
      host.icecap.firecracker-prebuilt
      host.icecap.firectl
    ]))

    meta.tcbSize

    dev.icecap.sel4-manual

    (with meta.display; lib.flatten [
      host-tools
      build-tools
      (lib.attrValues host-kernel)
      realm-kernel
    ])
  ];

  pure = [
    cached

    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      meta.tests.backtrace
      meta.tests.realm-vm
      meta.tests.analysis
      meta.tests.benchmark-utilisation
    ])

    meta.tests.firecracker.rpi4.boot
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
