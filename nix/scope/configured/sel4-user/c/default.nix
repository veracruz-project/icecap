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

        NIX_CFLAGS_COMPILE = extraCFlagsCompile;
        NIX_CFLAGS_LINK = extraCFlagsLink;

        inherit buildInputs propagatedBuildInputs;

        makeFlags = [
          "-f" makefile.${attr}
          "ROOTS=${lib.concatMapStringsSep " " (x: "${x.${attr}}/icecap.mk") roots}"
          "OUT=$(out)"
          "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
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

  root-task-tls-lds = icecapSrc.relative "c/support/root-task-tls.lds";
  root-task-eh-lds = icecapSrc.relative "c/support/root-task-eh.lds";

  mkRoot = attrs: mk (attrs // {
    extraCFlagsLink = (attrs.extraCFlagsLink or []) ++ [
      "-T" root-task-tls-lds
    ];
  });

  mkBasic = { name, path ? name, inputs ? [], extra ? {} }:
    mk {
      inherit name;
      root = icecapSrc.relativeSplit "c/${path}";
      propagatedBuildInputs = [
        libsel4
      ] ++ inputs;
      inherit extra;
    };

in

rec {

  inherit mk mkRoot;

  icecap-runtime = mkBasic {
    name = "icecap-runtime";
    extra.ICECAP_RUNTIME_CONFIG_IN = writeText "config_in.h" ''
      #pragma once
    '';
  };

  icecap-runtime-root = mkBasic {
    name = "icecap-runtime";
    extra.ICECAP_RUNTIME_CONFIG_IN = writeText "config_in.h" ''
      #pragma once
      #define ICECAP_RUNTIME_ROOT
      #define ICECAP_RUNTIME_ROOT_STACK_SIZE 0x200000
      #define ICECAP_RUNTIME_ROOT_HEAP_SIZE 0x200000
    '';
  };

  icecap-utils = mkBasic {
    name = "icecap-utils";
    inputs = [
      icecap-runtime # TODO invert
    ];
  };

  icecap-pure = mkBasic {
    name = "icecap-pure";
    inputs = [
      icecap-utils
    ];
  };

  icecap-mirage-glue = mk {
    stdenv = stdenvMirage;
    name = "icecap-mirage-glue";
    root = icecapSrc.relativeSplit "c/icecap-mirage-glue";
    propagatedBuildInputs = [
      stdenvMirage.cc.libc # HACK
      libsel4
      icecap-runtime
      icecap-ocaml-runtime
      icecap-utils # HACK
    ];
  };

  cpio = mkBasic rec {
    name = "cpio";
    path = "boot/${name}";
  };

  capdl-support-hack = mkBasic rec {
    name = "capdl-support-hack";
    path = "boot/${name}";
    inputs = [
      icecap-utils
      icecap-pure
    ];
  };

}
