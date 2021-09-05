{ object-sizes
, lib, runCommand, writeText
, buildPackages, python3Packages
, icecapSrc
, icecapPlat
, seL4EcosystemRepos

, icecap-append-devices
, icecap-serialize-runtime-config
, dyndl-serialize-spec
}:

{ config
, src
}:


let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;
  };

  capdlSrc = seL4EcosystemRepos.capdl.extendInnerSuffix "python-capdl-tool";
  icedlSrc = icecapSrc.relativeSplit "python";
  srcSplit = icecapSrc.absoluteSplit src;
  f = attr: runCommand "manifest" {
    nativeBuildInputs = [
      buildPackages.stdenv.cc
      icecap-append-devices
      icecap-serialize-runtime-config
      buildPackages.icecap.serializeConfig.generic
      buildPackages.icecap.serializeConfig.fault-handler
      buildPackages.icecap.serializeConfig.timer-server
      buildPackages.icecap.serializeConfig.serial-server
      buildPackages.icecap.serializeConfig.host-vmm
      buildPackages.icecap.serializeConfig.realm-vmm
      buildPackages.icecap.serializeConfig.resource-server
      buildPackages.icecap.serializeConfig.event-server

      dyndl-serialize-spec
    ] ++ (with python3Packages; [
      future six
      aenum orderedset sortedcontainers
      pyyaml pyelftools pyfdt
    ]);
    PYTHONPATH_ = lib.concatMapStringsSep ":" (x: x.${attr}) [ srcSplit icedlSrc capdlSrc ];
    CONFIG = writeText "config.json" (builtins.toJSON augmentedConfig);
    setup = ''
      export PYTHONPATH=$PYTHONPATH_:$PYTHONPATH
    '';
    passthru.env = f "env";
    passthru.config = augmentedConfig;
    shellHook = ''
      eval "$setup"
      export OUT_DIR=.
      b() {
        python3 -m x
      }
    '';
  } ''
    eval "$setup"
    export OUT_DIR=$out
    mkdir $OUT_DIR
    python3 -m x
  '';
in
  f "store"
