{ object-sizes
, lib, runCommand, writeText
, buildPackages, python3Packages
, icecapSrcAbsSplit, icecapSrcRelSplit, mkTrivialSrc
, icecapPlat
, repos

, append-icecap-devices
, serialize-runtime-config
, serialize-generic-config
, serialize-fault-handler-config
, serialize-timer-server-config
, serialize-serial-server-config
, serialize-qemu-ring-buffer-server-config
, serialize-vmm-config
, serialize-caput-config

, serialize-dyndl-spec
}:

{ config
, src
}:


let
  augmentedConfig = config // {
    plat = icecapPlat;
    object_sizes = object-sizes;
  };

  capdlSrc = mkTrivialSrc (repos.rel.capdl "python-capdl-tool");
  icedlSrc = icecapSrcRelSplit "python";
  srcSplit = icecapSrcAbsSplit src;
  f = attr: runCommand "manifest" {
    nativeBuildInputs = [
      buildPackages.stdenv.cc
      append-icecap-devices
      serialize-runtime-config
      serialize-generic-config
      serialize-fault-handler-config
      serialize-timer-server-config
      serialize-serial-server-config
      serialize-qemu-ring-buffer-server-config
      serialize-vmm-config
      serialize-caput-config

      serialize-dyndl-spec
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
    '';
  } ''
    eval "$setup"
    export OUT_DIR=$out
    mkdir $OUT_DIR
    python3 -m x
  '';
in
  f "store"