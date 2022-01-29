{ buildOpamPackage
, which
}:

{ main }:

buildOpamPackage rec {
  pname = "mirage-main";
  version = "0.1";
  phases = [ "configurePhase" "buildPhase" "installPhase" ];

  nativeBuildInputs = [
    which
  ];

  buildInputsOCaml = [
    main
  ];

  setToolchain = true;

  buildPhase = ''
    mkdir bin
    ln -s $(which $LD) bin/ld
    export PATH=bin:$PATH
    ocamlfind ocamlopt -package main -c ${./x.ml} -o x.cmx
    ocamlfind ocamlopt -package main -linkpkg -output-obj -o libmirage.o x.cmx
    $AR r libmirage.a libmirage.o
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp libmirage.a $out/lib
  '';

  NIX_LDFLAGS = [
    "-lcstruct_stubs"
    "-ltcpip_xen_stubs" # HACK
    "-lbase_stubs"
  ];

  passthru = {
    inherit main;
    providesLibs = [
      "mirage"
    ];
  };
}
