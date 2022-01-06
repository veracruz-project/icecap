{ lib, writeText, runCommand, linkFarm
, buildPlatform, hostPlatform, targetPlatform
}:

self:

let
  callPackage = self.newScope (lib.optionalAttrs (hostPlatform.config == "aarch64-none-elf") {
    # TODO abstract
    stdenv = self.stdenvMirage;
  });

  targetCC = self.otherSplices.selfTargetTarget.stdenvMirage.cc;

  inherit (self) otherSplices;
  inherit (self) ocaml ocamlBuildBuild;

  # TODO
  #   build-time CAML_LD_LIBRARY_PATH
  #   add run-time CAML_LD_LIBRARY_PATH of build-time -dllpath
  #   see https://caml.inria.fr/pub/docs/manual-ocaml/runtime.html#s-ocamlrun-dllpath

  applyFindlibConf = args:
    let
      conf = mkFindlibConf args;
    in ''
      export OCAMLFIND_CONF=$NIX_BUILD_TOP/findlib.conf
      substitute ${conf}/etc/findlib.conf $OCAMLFIND_CONF --subst-var out
      if test -d ${conf}/etc/findlib.conf.d; then
        mkdir $OCAMLFIND_CONF.d
        for x in $(ls ${conf}/etc/findlib.conf.d); do
          substitute ${conf}/etc/findlib.conf.d/$x $OCAMLFIND_CONF.d/$x --subst-var out
        done
      fi
    '';

  mkFindlibConf = { buildInputs ? [], nativeBuildInputs ? [] }: linkFarm "findlib-conf" (
    if buildPlatform == hostPlatform
    then [
      { name = "etc/findlib.conf";
        path = writeText "findlib.conf" ''
          ldconf     = "ignore"
          destdir    = "@out@/lib"
          path       = "${otherSplices.selfBuildHost.ocamlfind.dummies}/lib:${lib.concatMapStringsSep ":" (x: "${x}/lib") (buildInputs ++ nativeBuildInputs)}"
          stdlib     = "${otherSplices.selfBuildHost.ocaml}/lib/ocaml"
          ocamlc     = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlc"
          ocamlopt   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlopt"
          ocamlcp    = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlcp"
          ocamlmklib = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlmklib"
          ocamlmktop = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlmktop"
          ocamldoc   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamldoc"
          ocamldep   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamldep"
        '';
      }
    ]
    else [
      { name = "etc/findlib.conf";
        path = writeText "findlib.conf" ''
          ldconf     = "ignore"
          destdir    = "@out@/lib"
          path       = "${otherSplices.selfBuildBuild.ocamlfind.dummies}/lib:${lib.concatStringsSep ":" (map (x: "${x}/lib") nativeBuildInputs)}"
          stdlib     = "${otherSplices.selfBuildBuild.ocaml}/lib/ocaml"
          ocamlc     = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamlc"
          ocamlopt   = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamlopt"
          ocamlcp    = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamlcp"
          ocamlmklib = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamlmklib"
          ocamlmktop = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamlmktop"
          ocamldoc   = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamldoc"
          ocamldep   = "${otherSplices.selfBuildBuild.ocaml}/bin/ocamldep"
        '';
      }
      { name = "etc/findlib.conf.d/mycross.conf";
        path = writeText "mycross.conf" ''
          ldconf(mycross)     = "ignore"
          destdir(mycross)    = "@out@/mycross-sysroot/lib/"
          path(mycross)       = "${otherSplices.selfBuildHost.ocamlfind.dummies}/lib:${lib.concatStringsSep ":" (map (x: "${x}/mycross-sysroot/lib/") buildInputs)}"
          stdlib(mycross)     = "${otherSplices.selfBuildHost.ocaml}/lib/ocaml"
          ocamlc(mycross)     = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlc"
          ocamlopt(mycross)   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlopt"
          ocamlcp(mycross)    = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlcp"
          ocamlmklib(mycross) = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlmklib"
          ocamlmktop(mycross) = "${otherSplices.selfBuildHost.ocaml}/bin/ocamlmktop"
          ocamldoc(mycross)   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamldoc"
          ocamldep(mycross)   = "${otherSplices.selfBuildHost.ocaml}/bin/ocamldep"
        '';
      }
    ]
  );

in {

  ocamlPackages = callPackage ./packages {};

  ocaml = callPackage ./compiler {
    inherit ocamlBuildBuild targetCC;
  };

  ocamlBuildBuild = otherSplices.selfBuildBuild.ocaml;
  buildPackagesOCaml = otherSplices.selfBuildHost.ocamlPackages;

  ocamlfind = callPackage ./tools/ocamlfind {};
  ocamlbuild = callPackage ./tools/ocamlbuild {};
  dune = callPackage ./tools/dune {};
  opaline = callPackage ./tools/opaline {};
  opam-file-format = callPackage ./tools/opam-file-format {};

  buildDunePackage = callPackage ./build-support/build-dune-package {};
  buildOpamPackage = callPackage ./build-support/build-opam-package {};
  buildTopkgPackage = callPackage ./build-support/build-topkg-package {};

  inherit mkFindlibConf applyFindlibConf;

  ocamlView = runCommand "ocaml-view" {} ''
    mkdir -p $out/bin
    ln -s ${ocaml}/bin/ocaml     $out/bin
    ln -s ${ocaml}/bin/ocamlrun* $out/bin
    ln -s ${ocaml}/bin/ocamlyacc $out/bin
    ln -s ${ocaml}/bin/ocamllex  $out/bin
  '';

  # Mirage

  mkMirageLibrary = callPackage ./mirage/mk-mirage-library {};

  mirage-icecap = callPackage ./mirage/mirage-icecap.nix {};

  icecap-ocaml-runtime = otherSplices.selfBuildHost.icecap-ocaml-runtime-build;
  icecap-ocaml-runtime-build = callPackage ./mirage/icecap-ocaml-runtime {
    inherit targetCC;
  };

}
