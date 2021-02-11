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
icecap.byIceCapPlat (icecapPlat:
  let

    config = callPackage ./config.nix {
      inherit icecapPlat;
    };

    mkInstance = f: { cmakeConfig }: args:
      let
        configuredScope = icecap.configure {
          inherit cmakeConfig icecapPlat;
        };
        instancesScope = lib.makeScope configuredScope.newScope (configuredScope.callPackage ./scope {
          inherit icecapExtraConfig;
        });
        instanceScope = lib.makeScope instancesScope.newScope (instancesScope.callPackage f args);
      in {
        cscope = configuredScope;
        iscope = instancesScope;
      } // instanceScope;

    mkBasicInstanceWith = cmakeConfig: f: args: mkInstance f {
      inherit cmakeConfig;
    } args;

    mkBasicInstance = cmakeConfig: f: mkBasicInstanceWith cmakeConfig f {};

  in {

    test = {
      sel4test = mkBasicInstance config.sel4test ./test/sel4test;
      host = mkBasicInstance config.icecap ./test/host;
      host-and-adjacent-vm = mkBasicInstance config.icecap ./test/host-and-adjacent-vm;
      timer-and-serial = mkBasicInstance config.icecap ./test/timer-and-serial;
      timer-and-serial-from-realm = mkBasicInstance config.icecap ./test/timer-and-serial-from-realm;
      mirage = mkBasicInstance config.icecap ./test/mirage;
    };

    demos = {
      minimal-root = mkBasicInstance config.icecap ./demos/minimal-root;
      minimal = mkBasicInstance config.icecap ./demos/minimal;
      realm-vm = mkBasicInstance config.icecap ./demos/realm-vm;
    };

    bench = {
      baseline = lib.makeScope newScope (callPackage ./bench/baseline {
        inherit icecapPlat icecapExtraConfig;
      });
    };

  }
)
