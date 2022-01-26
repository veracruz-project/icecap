{ lib, pkgs, instances, adHocBuildTests, generatedDocs }:

let
  inherit (pkgs) dev none linux musl;

  forEachIn = lib.flip lib.concatMap;
  forEachConfigured = f: lib.mapAttrsToList (lib.const f) pkgs.none.icecap.configured;

  cached = [
    (map (lib.mapAttrsToList (_: plat: plat.run)) [
      instances.tests.backtrace
    ])
  ];

  pure = [
    cached

    (forEachIn [ linux musl ] (host: [
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
    ])
  ];

  impure = [
    adHocBuildTests.allList
    generatedDocs.html
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
