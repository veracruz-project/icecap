{ lib, buildPackages, runCommand, writeText
, python3Packages

, icecapSrc, seL4EcosystemRepos

, icecapPlat
, object-sizes

, icecap-append-devices
, icecap-serialize-runtime-config
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
, dyndl-serialize-spec
}:

{ config
, src
}:

let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;

    # HACK
    hack_realm_affinity = 1;
  };

  capdlSrc = seL4EcosystemRepos.capdl.extendInnerSuffix "python-capdl-tool";
  icedlSrc = icecapSrc.relativeSplit "python";
  srcSplit = icecapSrc.absoluteSplit src;

  f = attr: runCommand "manifest" {

    nativeBuildInputs = [
      buildPackages.stdenv.cc
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

    CONFIG = writeText "config.json" (builtins.toJSON augmentedConfig);

    PYTHONPATH_ = lib.concatMapStringsSep ":" (x: x.${attr}) [ srcSplit icedlSrc capdlSrc ];

    setup = ''
      export PYTHONPATH=$PYTHONPATH_:$PYTHONPATH
    '';

    passthru = {
      env = f "env";
      config = augmentedConfig;
    };

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
