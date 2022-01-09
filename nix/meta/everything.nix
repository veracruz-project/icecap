{ lib, pkgs, meta }:

let
  inherit (pkgs) dev none linux musl;

  cached = [
    (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (_: configured: [
      configured.icecapFirmware.display
    ]))

    (with meta.display; lib.flatten [
      (lib.attrValues host-kernel)
      realm-kernel
      host-tools
      build-tools
    ])

    (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) meta.demos)
    (lib.mapAttrsToList (_: example: example.run) meta.examples)
  ];

  pure = [
    cached

    meta.tcbSize

    dev.icecap.sel4-manual
    dev.icecap.bindgen

    (lib.flip lib.concatMap [ linux musl ] (host: [
      host.icecap.icecap-host
      host.icecap.firecracker
      host.icecap.firecracker-prebuilt
      host.icecap.firectl
    ]))

    (lib.flip lib.concatMap [ dev linux musl ] (host: [
      host.icecap.crosvm-9p-server
    ]))

    (lib.flip lib.mapAttrsToList pkgs.none.icecap.configured (_: configured: [
      configured.sysroot-rs
    ]))

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
