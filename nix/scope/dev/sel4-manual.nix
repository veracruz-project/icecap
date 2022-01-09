{ stdenv
, python3Packages, texlive, doxygen
, icecapExternalSrc
}:

let
  texlive-env = with texlive; combine {
    inherit
      collection-fontsrecommended
      collection-latexextra
      collection-metapost
      collection-bibtexextra
      roboto mweights
    ;
  };

in
stdenv.mkDerivation {
  name = "sel4-manual";

  src = icecapExternalSrc.seL4;

  nativeBuildInputs = [
    python3Packages.sel4-deps
    texlive-env
    doxygen
  ];

  configurePhase = ''
    mkdir bin
    cat > bin/git <<EOF
    #!/bin/sh
    echo 1970-01-01 00:00:00 +0000
    EOF
    chmod +x bin/git

    export PATH="$(pwd)/bin:$PATH"
  '';

  buildPhase = ''
    cd manual
    make all markdown
  '';

  installPhase = ''
    mkdir $out
    cp -r manual.pdf generated_markdown $out
  '';
}
