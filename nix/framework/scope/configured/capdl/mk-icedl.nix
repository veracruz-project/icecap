{ lib, buildPackages, runCommand, writeText
, python3Packages

, icecapSrc, icecapExternalSrc

, icecapPlat
, object-sizes

, icecap-serialize-runtime-config
, dyndl-serialize-spec
}:

{ config
, script ? null
, command ? "python3 ${script}"
}:

let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;
  };

  augmentedConfigJSON = writeText "config.json" (builtins.toJSON augmentedConfig);

  capdlSrc = icecapExternalSrc.capdl.extendInnerSuffix "python-capdl-tool";
  icedlSrc = icecapSrc.relative "python";

in
runCommand "manifest" {

  nativeBuildInputs = [
    icecap-serialize-runtime-config
    dyndl-serialize-spec
  ] ++ (with python3Packages; [
    future six
    aenum orderedset sortedcontainers
    pyyaml pyelftools pyfdt
  ]);

  PYTHONPATH_ = lib.concatStringsSep ":" [ icedlSrc capdlSrc ];

  CONFIG = augmentedConfigJSON;

  passthru = {
    config = augmentedConfig;
  };
} ''
  export PYTHONPATH=$PYTHONPATH_:$PYTHONPATH
  export OUT_DIR=$out
  ${command}
''
