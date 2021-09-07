{ lib, stdenv, hostPlatform
, fetchurl
}:

{ name, version, date ? null, sha256, components, binaries, postInstall ? "" }:

let
  dateSuffixWith = prefix: lib.optionalString (date != null) "${prefix}${date}";

in stdenv.mkDerivation rec {

  pname = "${name}-bootstrap${dateSuffixWith "-"}";
  inherit version date;

  src = fetchurl {
    url = "https://static.rust-lang.org/dist${dateSuffixWith "/"}/${name}-${version}-${hostPlatform.config}.tar.gz";
    inherit sha256;
  };

  postPatch = ''
    patchShebangs .
  '';

  inherit postInstall;

  installPhase = ''
    ./install.sh --prefix=$out --components=${lib.concatStringsSep "," components}
    dynamic_linker=$(cat $NIX_CC/nix-support/dynamic-linker)
    ${lib.concatMapStrings (binary: ''
      patchelf --set-interpreter $dynamic_linker $out/bin/${binary}
    '') binaries}

    runHook postInstall
  '';

  # Do not use `wrapProgram` on $out/bin/* here.
  # https://github.com/rust-lang/rust/issues/34722#issuecomment-232164943
}
