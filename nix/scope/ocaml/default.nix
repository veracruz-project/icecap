{ lib, writeText, runCommand, linkFarm
, buildPlatform, hostPlatform, targetPlatform
}:

self:

let
  callPackage = self.newScope (lib.optionalAttrs (hostPlatform.config == "aarch64-none-elf") {
    # TODO abstract
    stdenv = self.stdenvMirage;
  });

  targetCC = self.pkgsTargetTargetScope.stdenvMirage.cc;

  inherit (self) pkgsBuildHostScope pkgsBuildBuildScope;
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
          path       = "${pkgsBuildHostScope.ocamlfind.dummies}/lib:${lib.concatMapStringsSep ":" (x: "${x}/lib") (buildInputs ++ nativeBuildInputs)}"
          stdlib     = "${pkgsBuildHostScope.ocaml}/lib/ocaml"
          ocamlc     = "${pkgsBuildHostScope.ocaml}/bin/ocamlc"
          ocamlopt   = "${pkgsBuildHostScope.ocaml}/bin/ocamlopt"
          ocamlcp    = "${pkgsBuildHostScope.ocaml}/bin/ocamlcp"
          ocamlmklib = "${pkgsBuildHostScope.ocaml}/bin/ocamlmklib"
          ocamlmktop = "${pkgsBuildHostScope.ocaml}/bin/ocamlmktop"
          ocamldoc   = "${pkgsBuildHostScope.ocaml}/bin/ocamldoc"
          ocamldep   = "${pkgsBuildHostScope.ocaml}/bin/ocamldep"
        '';
      }
    ]
    else [
      { name = "etc/findlib.conf";
        path = writeText "findlib.conf" ''
          ldconf     = "ignore"
          destdir    = "@out@/lib"
          path       = "${pkgsBuildBuildScope.ocamlfind.dummies}/lib:${lib.concatStringsSep ":" (map (x: "${x}/lib") nativeBuildInputs)}"
          stdlib     = "${pkgsBuildBuildScope.ocaml}/lib/ocaml"
          ocamlc     = "${pkgsBuildBuildScope.ocaml}/bin/ocamlc"
          ocamlopt   = "${pkgsBuildBuildScope.ocaml}/bin/ocamlopt"
          ocamlcp    = "${pkgsBuildBuildScope.ocaml}/bin/ocamlcp"
          ocamlmklib = "${pkgsBuildBuildScope.ocaml}/bin/ocamlmklib"
          ocamlmktop = "${pkgsBuildBuildScope.ocaml}/bin/ocamlmktop"
          ocamldoc   = "${pkgsBuildBuildScope.ocaml}/bin/ocamldoc"
          ocamldep   = "${pkgsBuildBuildScope.ocaml}/bin/ocamldep"
        '';
      }
      { name = "etc/findlib.conf.d/mycross.conf";
        path = writeText "mycross.conf" ''
          ldconf(mycross)     = "ignore"
          destdir(mycross)    = "@out@/mycross-sysroot/lib/"
          path(mycross)       = "${pkgsBuildHostScope.ocamlfind.dummies}/lib:${lib.concatStringsSep ":" (map (x: "${x}/mycross-sysroot/lib/") buildInputs)}"
          stdlib(mycross)     = "${pkgsBuildHostScope.ocaml}/lib/ocaml"
          ocamlc(mycross)     = "${pkgsBuildHostScope.ocaml}/bin/ocamlc"
          ocamlopt(mycross)   = "${pkgsBuildHostScope.ocaml}/bin/ocamlopt"
          ocamlcp(mycross)    = "${pkgsBuildHostScope.ocaml}/bin/ocamlcp"
          ocamlmklib(mycross) = "${pkgsBuildHostScope.ocaml}/bin/ocamlmklib"
          ocamlmktop(mycross) = "${pkgsBuildHostScope.ocaml}/bin/ocamlmktop"
          ocamldoc(mycross)   = "${pkgsBuildHostScope.ocaml}/bin/ocamldoc"
          ocamldep(mycross)   = "${pkgsBuildHostScope.ocaml}/bin/ocamldep"
        '';
      }
    ]
  );

in {

  ocamlPackages = callPackage ./packages {};

  ocaml = callPackage ./compiler {
    inherit ocamlBuildBuild targetCC;
  };

  ocamlBuildBuild = pkgsBuildBuildScope.ocaml;
  buildPackagesOCaml = pkgsBuildHostScope.ocamlPackages;

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

  icecap-ocaml-runtime = pkgsBuildHostScope.icecap-ocaml-runtime-build;
  icecap-ocaml-runtime-build = callPackage ./mirage/icecap-ocaml-runtime {
    inherit targetCC;
  };

}
