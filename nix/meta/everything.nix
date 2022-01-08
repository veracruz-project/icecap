{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  cached = [
    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)

    (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (_: configured: [
      configured.sysroot-rs
    ]))

    (lib.flip lib.concatMap [ dev linux ] (host: [
      host.icecap.crosvm-9p-server
    ]))

    meta.tcbSize

    dev.icecap.sel4-manual
  ];

  pure = [
    cached

    musl.icecap.icecap-host
    musl.icecap.firecracker
    musl.icecap.firecracker-prebuilt
    musl.icecap.firectl

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
