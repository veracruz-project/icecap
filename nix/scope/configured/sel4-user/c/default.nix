{ lib, linkFarm, writeText
, stdenv, stdenvMirage
, icecapSrc
, icecap-ocaml-runtime
, libsel4, musl
}:

let

  _stdenv = stdenv;

  mk =
    { name, root ? null, roots ? [ root ]
    , extraCFlagsCompile ? []
    , extraCFlagsLink ? []
    , buildInputs ? [], propagatedBuildInputs ? []
    , passthru ? {}
    , extra ? {}
    , stdenv ? _stdenv
    }:
    let
      makefile = icecapSrc.relativeSplit "c/Makefile";

      f = attr: stdenv.mkDerivation ({
        inherit name;

        phases = [ "buildPhase" "installPhase" "fixupPhase" ];
        dontStrip = true;
        dontPatchELF = true;

        hardeningDisable = [ "all" ];
        NIX_CFLAGS_COMPILE = extraCFlagsCompile;
        NIX_CFLAGS_LINK = extraCFlagsLink;

        inherit buildInputs propagatedBuildInputs;

        makeFlags = [
          "-f" makefile.${attr}
          "ROOTS=${lib.concatMapStringsSep " " (x: "${x.${attr}}/icecap.mk") roots}"
          "OUT=$(out)"
        ];

        passthru = {
          env = f "env";
        } // passthru;

        shellHook = ''
          m() {
            make -j$NIX_BUILD_CORES SHELL=$SHELL $makeFlags $buildFlags "$@"
          }
          b() {
            buildPhase
          }
        '';
      } // extra);

    in f "store";

  root-task-tls-lds = icecapSrc.relative "c/lds/root-task-tls.lds";
  root-task-eh-lds = icecapSrc.relative "c/lds/root-task-eh.lds";

  mkRoot = attrs: mk (attrs // {
    extraCFlagsLink = (attrs.extraCFlagsLink or []) ++ [
      "-T" root-task-tls-lds
    ];
  });

  mkBasicWith = name: inputs: extra: mk {
    inherit name;
    root = icecapSrc.relativeSplit "c/${name}";
    propagatedBuildInputs = [
      libsel4
    ] ++ inputs;
    inherit extra;
  };

  mkBasic = name: inputs: mkBasicWith name inputs {};

in

rec {

  inherit mk mkRoot;

  icecap-autoconf = mkBasic "icecap-autoconf" [
  ];

  icecap-runtime = mkBasicWith "icecap-runtime" [
    icecap-autoconf
  ] {
    CONFIG = linkFarm "config" [
      { name = "icecap_runtime/config.h";
        path = writeText "config.h" ''
          #pragma once
        '';
      }
    ];
  };

  icecap-runtime-root = mkBasicWith "icecap-runtime" [
    icecap-autoconf
  ] {
    CONFIG = linkFarm "config" [
      { name = "icecap_runtime/config.h";
        path = writeText "config.h" ''
          #pragma once
          #define ICECAP_RUNTIME_ROOT
          #define ICECAP_RUNTIME_ROOT_STACK_SIZE 0x200000
          #define ICECAP_RUNTIME_ROOT_HEAP_SIZE 0x200000
        '';
      }
    ];
  };

  icecap-utils = mkBasic "icecap-utils" [
    icecap-autoconf
    icecap-runtime
  ];

  icecap-pure = mkBasic "icecap-pure" [
    icecap-autoconf
  ];

  icecap-mirage-glue = mk {
    stdenv = stdenvMirage;
    name = "icecap-mirage-glue";
    root = icecapSrc.relativeSplit "c/icecap-mirage-glue";
    propagatedBuildInputs = [
      stdenvMirage.cc.libc # HACK
      libsel4
      icecap-autoconf
      icecap-runtime
      icecap-ocaml-runtime
      icecap-utils # HACK
    ];
  };

  cpio = mkBasic "cpio" [
  ];

  capdl-support-hack = mkBasic "capdl-support-hack" [
    icecap-autoconf
    icecap-utils
    icecap-pure
  ];

}
