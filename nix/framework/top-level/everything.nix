{ lib, pkgs, mkEverything, instances, automatedTests, adHocBuildTests, generatedDocs }:

let
  inherit (pkgs) dev none linux musl;

  forEachIn = lib.flip lib.concatMap;
  forEachConfigured = f: lib.mapAttrsToList (lib.const f) pkgs.none.icecap.configured;

in mkEverything {

  cached = [
    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      instances.tests.backtrace
    ])

    automatedTests.runAll
  ];

  extraPure = [
    (forEachConfigured (configured: [
      configured.sysroot-rs
    ]))

    (forEachIn [ dev linux musl ] (host: [
      host.icecap.crosvm-9p-server
    ]))
  ];

  impure = [
    adHocBuildTests.allList
    generatedDocs.external.html
  ];

  excess = [
    generatedDocs.complete.html

    (forEachIn [ dev ] (host: [
      host.icecap.bindgen
    ]))
  ];
}
