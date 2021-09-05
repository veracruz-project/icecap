{ stdenv, stdenvMirage, lib
, icecapSrc
, icecap-ocaml-runtime
, libsel4, musl
, linkFarm, writeText
}:

let

  _stdenv = stdenv;

  mk =
    { name, root ? null, roots ? [ root ], graph ? {}
    , extraCFlagsCompile ? []
    , extraCFlagsLink ? []
    , buildInputs ? [], propagatedBuildInputs ? []
    , passthru ? {}
    , extra ? {}
    , stdenv ? _stdenv
    }:
    let
      makefile = icecapSrc.absoluteSplit ./Makefile;

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
          inherit graph;
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

  root-task-tls-lds = ./root-task-tls.lds;
  root-task-eh-lds = ./root-task-eh.lds;

  mkRoot = attrs: mk (attrs // {
    extraCFlagsLink = (attrs.extraCFlagsLink or []) ++ [
      "-T" root-task-tls-lds
    ];
  });

  mkBasicWith = name: inputs: graph: extra: mk {
    inherit name;
    root = icecapSrc.relativeSplit "c/${name}";
    propagatedBuildInputs = [
      libsel4
    ] ++ inputs;
    inherit graph extra;
  };

  mkBasic = name: inputs: graph: mkBasicWith name inputs graph {};

in

rec {

  inherit mk mkRoot;

  icecap-autoconf = mkBasic "icecap-autoconf" [
  ] {
  };

  icecap-runtime = mkBasicWith "icecap-runtime" [
    icecap-autoconf
  ] {
    "icecap_runtime" = [ "sel4" ];
  } {
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
    "icecap_runtime" = [ "sel4" ];
  } {
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
  ] {
    "icecap_utils" = [ "sel4" "icecap_runtime" ];
  };

  icecap-pure = mkBasic "icecap-pure" [
    icecap-autoconf
  ] {
    "icecap_pure" = [ ];
  };

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
    graph = {
      "icecap_mirage_glue" = [ ];
    };
  };

  cpio = mkBasic "cpio" [
  ] {
    "cpio" = [ ];
  };

  capdl-support-hack = mkBasic "capdl-support-hack" [
    icecap-autoconf
    icecap-utils
    icecap-pure
  ] {
    "capdl_support_hack" = [ "sel4" "icecap_utils" "icecap_pure" ];
  };

}
