{ lib, linkFarm, writeText
, stdenv, stdenvMirage
, icecapSrc
, icecap-ocaml-runtime
, libsel4, musl
, platformInfo, icecapExternalSrc
, root-task-tls-lds
, root-task-eh-lds
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

  mkLibs = isRoot: lib.fix (self: with self; {

    icecap-runtime = mkBasic {
      name = "icecap-runtime";
      extra.ICECAP_RUNTIME_CONFIG_IN = writeText "config_in.h" (''
        #pragma once
      '' + lib.optionalString isRoot ''
        #define ICECAP_RUNTIME_ROOT
      '');
    };

    icecap-utils = mkBasic {
      name = "icecap-utils";
      inputs = [
        icecap-runtime
      ];
    };

    icecap-some-libc = mkBasic {
      name = "icecap-some-libc";
      inputs = [
        icecap-utils
      ];
    };

    cpio = mkBasic rec {
      name = "cpio";
      path = "boot/${name}";
    };

  } // lib.optionalAttrs (!isRoot) {

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

  } // lib.optionalAttrs isRoot {

    capdl-loader-shim = mkBasic rec {
      name = "capdl-loader-shim";
      path = "boot/${name}";
      inputs = [
        icecap-utils
        icecap-some-libc
      ];
    };

    capdl-loader-core = mkBasic rec {
      name = "capdl-loader-core";
      path = "boot/${name}";
      inputs = [
        icecap-runtime
        icecap-some-libc
        icecap-utils
        cpio
        capdl-loader-shim
      ];
      extra.CAPDL_LOADER_EXTERNAL_SOURCE = icecapExternalSrc.capdl.extendInnerSuffix "capdl-loader-app";
      extra.CAPDL_LOADER_PLATFORM_INFO_H = platformInfo;
      extra.CAPDL_LOADER_CONFIG_IN_H = writeText "config_in.h" ''
        #pragma once
        #define CONFIG_CAPDL_LOADER_MAX_OBJECTS 10000
      '';
    };
  });

  rootLibs = mkLibs true;
  nonRootLibs = mkLibs false;

in {
  inherit mk mkRoot rootLibs nonRootLibs;
}
