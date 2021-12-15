{ lib, buildPackages, runCommand, writeText
, python3Packages

, icecapSrc, icecapExternalSrc

, icecapPlat
, object-sizes

, icecap-append-devices
, icecap-serialize-runtime-config
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
, dyndl-serialize-spec
}:

{ config
, action
}:

let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;

    # HACK
    hack_realm_affinity = 1;
  };

  augmentedConfigJSON = writeText "config.json" (builtins.toJSON augmentedConfig);

  capdlSrc = icecapExternalSrc.capdl.extendInnerSuffix "python-capdl-tool";
  icedlSrc = icecapSrc.relativeSplit "python";

  f = attr:

    let
      cmd =
        if lib.isString action
        then {
          firmware = "python3 -m icecap_hypervisor.cli firmware ${augmentedConfigJSON} -o $out";
          linux-realm = "python3 -m icecap_hypervisor.cli linux-realm ${augmentedConfigJSON} -o $out";
        }.${action}
        else "CONFIG=${augmentedConfigJSON} OUT_DIR=${{ env = "."; store = "$out"; }.${attr}} python3 ${action.script.${attr}}";

    in
    runCommand "manifest" {

      nativeBuildInputs = [
        icecap-append-devices
        icecap-serialize-runtime-config
        icecap-serialize-builtin-config
        icecap-serialize-event-server-out-index
        dyndl-serialize-spec
      ] ++ (with python3Packages; [
        future six
        aenum orderedset sortedcontainers
        pyyaml pyelftools pyfdt
      ]);

      PYTHONPATH_ = lib.concatMapStringsSep ":" (x: x.${attr}) [ icedlSrc capdlSrc ];

      setup = ''
        export PYTHONPATH=$PYTHONPATH_:$PYTHONPATH
      '';

      passthru = {
        env = f "env";
        config = augmentedConfig;
      };

      shellHook = ''
        eval "$setup"
        b() {
          ${cmd}
        }
      '';

    } ''
      eval "$setup"
      ${cmd}
    '';

in
  f "store"
