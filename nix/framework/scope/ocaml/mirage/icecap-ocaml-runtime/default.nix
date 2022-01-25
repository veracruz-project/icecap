{ stdenv, hostPlatform, targetPlatform
, fetchFromGitHub
, ocamlView, targetCC
}:

stdenv.mkDerivation rec {
  name = "icecap-ocaml-runtime";

  src = fetchFromGitHub {
    owner = "ocaml";
    repo = "ocaml";
    rev = "4.07.1";
    sha256 = "0dm1n9n3vf1awvw77wzxcfp36is0vf1mr3r66a218pzsc5ckbycj";
  };

  patches = [
    ../../compiler/cross-compiler.patch
  ];

  hardeningDisable = [ "all" ];

  depsBuildBuild = [ ocamlView ];
  depsBuildTarget = [ targetCC ];

  postPatch = ''
    substituteInPlace configure --replace -O2 -O0
    sed -i 's,TOOLPREF=.*,TOOLPREF=${targetCC.targetPrefix},' configure
  '';

  configurePhase = ''
    ./configure \
      -host ${hostPlatform.config} \
      -target ${if targetPlatform.config == "aarch64-none-elf" then "aarch64-unknown-linux-gnu" else targetPlatform.config} \
      -no-ocamldoc \
      -no-ocamltest \
      -target-bindir $out/bin \
      -prefix $out

    substituteInPlace config/Makefile --replace SYSTEM=linux SYSTEM=sel4
  '';

  buildPhase = ''
    cp ${./s.h} byterun/caml/s.h
    cp ${./version.h} byterun/caml/version.h

    make -C asmrun libasmrun.a
  '';

  installPhase = ''
    install -D -T asmrun/libasmrun.a $out/lib/libsel4asmrun.a

    PUBLIC_INCLUDES=" \
      alloc.h callback.h config.h custom.h fail.h hash.h intext.h \
      io.h memory.h misc.h mlvalues.h printexc.h signals.h compatibility.h \
      s.h m.h \
      "

    for x in $PUBLIC_INCLUDES; do
      install -D -t $out/include/caml byterun/caml/$x
    done
  '';

  dontFixup = true;

  passthru = {
    providesLibs = [
      "sel4asmrun"
    ];
  };

}
