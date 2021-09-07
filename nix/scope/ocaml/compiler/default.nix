{ stdenv, buildPlatform, hostPlatform, targetPlatform
, runCommand, removeReferencesTo
, fetchurl, fetchFromGitHub
, ocamlBuildBuild, targetCC
}:

let

  name = "ocaml-${version}";
  majorVersion = "4";
  minorVersion = "07";
  patchVersion = "1";
  version = "${versionNoPatch}.${patchVersion}";
  versionNoPatch = "${majorVersion}.${minorVersion}";
  src = assert buildPlatform.config == hostPlatform.config; fetchurl {
    url = "http://caml.inria.fr/pub/distrib/ocaml-${versionNoPatch}/ocaml-${version}.tar.xz";
    sha256 = "1f07hgj5k45cylj1q3k5mk8yi02cwzx849b1fwnwia8xlcfqpr6z";
  };

  # name = "ocaml-${version}";
  # version = "4.08.0+beta3";
  # src = assert buildPlatform == hostPlatform; fetchFromGitHub {
  #   owner = "ocaml";
  #   repo = "ocaml";
  #   rev = "b23e894542ff396094cd5168e70d66233418415a";
  #   sha256 = "03yh3gan24r7awri04z2fpjwm6v7s318zfj37bqyj4q313f00j8z";
  # };

  ocamlView = runCommand "ocaml-view" {} ''
    mkdir -p $out/bin
    ln -s ${ocamlBuildBuild}/bin/ocamlrun* $out/bin
    ln -s ${ocamlBuildBuild}/bin/ocamlyacc $out/bin
  '';

  notCross = stdenv.mkDerivation rec {

    inherit name version src;

    prefixKey = "-prefix ";

    buildFlags = [ "world" "bootstrap" "world.opt" ];

    installTargets = [ "install" "installopt" ];

    postInstall = ''
      mkdir -p $out/include
      ln -sv $out/lib/ocaml/caml $out/include/caml
    '';

    # dontStrip = true;
    # dontFixup = true;

  };

  cross = stdenv.mkDerivation rec {

    inherit name version src;

    outputs = [ "out" "runtime" ];

    patches = [
      ./cross-compiler.patch
    ];

    depsBuildBuild = [ ocamlView ];
    depsBuildTarget = [ targetCC ];
    nativeBuildInputs = [ removeReferencesTo ];

    # NIX_DEBUG = 1;

    postPatch = ''
      sed -i 's,TOOLPREF=.*,TOOLPREF=${targetCC.targetPrefix},' configure
    '';

    configurePhase = ''
      ./configure \
        -host ${hostPlatform.config} \
        -target ${if targetPlatform.config == "aarch64-none-elf" then "aarch64-unknown-linux-gnu" else targetPlatform.config} \
        -no-ocamldoc \
        -no-ocamltest \
        -target-bindir $runtime/bin \
        -prefix $out
    '';
        # -verbose \

    # buildPhase = ''
    #   make world opt
    # '';
    #   # make world world.opt
    #   # make compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlbytecomp.cmxa compilerlibs/ocamloptcomp.cmxa

    buildFlags = [
      "world" "world.opt"
    ];

    # TODO fix build-platform ocamlrun hack

    installPhase = ''
      make install installopt

      mkdir -p $runtime/bin
      mv $out/bin/ocamlrun* $runtime/bin
      mv $out/bin/ocamlyacc $runtime/bin
      remove-references-to -t $out $runtime/bin/*

      ln -s ${ocamlView}/bin/ocamlrun* $out/bin
      ln -s ${ocamlView}/bin/ocamlyacc $out/bin

      rm $out/bin/ocamlcmt
      rm $out/bin/*.opt

      for x in $(find $out/bin -type l -printf '%l\n' | sed -n 's/\.opt$//p'); do
        ln -sf $out/bin/$x.byte $out/bin/$x
      done

      mkdir -p $out/include
      ln -sv $out/lib/ocaml/caml $out/include/caml
    '';

    dontStrip = true; # TODO unecessary
    dontFixup = true;

  };

in
  if hostPlatform.config == targetPlatform.config then notCross else cross
  # if hostPlatform.config != targetPlatform.config then notCross else cross
  # notCross
