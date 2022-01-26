{ lib, buildPackages, runCommand, writeText
, python3Packages

, icecapSrc, icecapExternalSrc

, icecapPlat
, object-sizes

, icecap-serialize-runtime-config
, dyndl-serialize-spec
}:

{ config
, action
, extraNativeBuildInputs ? []
}:

let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;
  };

  augmentedConfigJSON = writeText "config.json" (builtins.toJSON augmentedConfig);

  capdlSrc = icecapExternalSrc.capdl.extendInnerSuffix "python-capdl-tool";
  icedlSrc = icecapSrc.relativeSplit "python";

  f = attr:

    let
      cmd = "CONFIG=${augmentedConfigJSON} OUT_DIR=${{ env = "."; store = "$out"; }.${attr}} ${action.whole or "python3 ${action.script.${attr}}"}";

    in
    runCommand "manifest" {

      nativeBuildInputs = [
        icecap-serialize-runtime-config
        dyndl-serialize-spec
      ] ++ (with python3Packages; [
        future six
        aenum orderedset sortedcontainers
        pyyaml pyelftools pyfdt
      ]) ++ extraNativeBuildInputs;

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
