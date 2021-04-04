{ lib, callPackage
, icecap
, newScope
}:

let
  icecapExtraConfigDefault = {
    nfsDev = null; # example: "example.com:/export/nix/store";
  };

  icecapExtraConfigOverrides =
    let path = ../../config.nix;
    in lib.optionalAttrs (lib.pathExists path) (import path);

  icecapExtraConfig = icecapExtraConfigDefault // icecapExtraConfigOverrides;

in
icecap.byIceCapPlat (plat:
  let

    configs = lib.mapAttrs (profile: _: {
      inherit plat profile;
    }) {
      icecap = null;
      sel4test = null;
    };

    mkInstance = f: config: args:
      let
        configuredScope = icecap.configure config;
        instancesScope = lib.makeScope configuredScope.newScope (configuredScope.callPackage ./scope {
          inherit icecapExtraConfig;
        });
        instanceScope = lib.makeScope instancesScope.newScope (instancesScope.callPackage f args);
      in {
        cscope = configuredScope;
        iscope = instancesScope;
      } // instanceScope;

    mkBasicInstanceWith = config: f: args: mkInstance f config args;

    mkBasicInstance = config: f: mkBasicInstanceWith config f {};

  in {

    test = {
      sel4test = mkBasicInstance configs.sel4test ./test/sel4test;
      host = mkBasicInstance configs.icecap ./test/host;
      host-and-adjacent-vm = mkBasicInstance configs.icecap ./test/host-and-adjacent-vm;
      timer-and-serial = mkBasicInstance configs.icecap ./test/timer-and-serial;
      timer-and-serial-from-realm = mkBasicInstance configs.icecap ./test/timer-and-serial-from-realm;
    };

    demos = {
      minimal-root = mkBasicInstance configs.icecap ./demos/minimal-root;
      minimal = mkBasicInstance configs.icecap ./demos/minimal;
      realm-vm = mkBasicInstance configs.icecap ./demos/realm-vm;
      mirage = mkBasicInstance configs.icecap ./demos/mirage;
    };

    bench = {
      icecap = mkBasicInstance configs.icecap ./bench/icecap;
      baseline = lib.makeScope newScope (callPackage ./bench/baseline {
        inherit icecapExtraConfig;
        icecapPlat = plat;
      });
    };

    # HACK
    inherit mkInstance mkBasicInstance configs;
  }
)
