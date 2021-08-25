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
      realm-vm = mkBasicInstance configs.icecap ./test/realm-vm;
      host-2-stage = mkBasicInstance configs.icecap ./test/host-2-stage;
      firecracker = mkBasicInstance configs.icecap ./test/firecracker;
    };

    demos = {
      realm-vm = mkBasicInstance configs.icecap ./demos/realm-vm;
      minimal-root = mkBasicInstance configs.icecap ./demos/minimal-root;
      minimal = mkBasicInstance configs.icecap ./demos/minimal;
      mirage = mkBasicInstance configs.icecap ./demos/mirage;
    };

    bench = {
    };

    # HACK
    inherit mkInstance mkBasicInstance configs;
  }
)
