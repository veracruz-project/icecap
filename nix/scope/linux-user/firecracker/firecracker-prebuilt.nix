{ stdenv
, hostPlatform
, fetchurl
}:

let
  arch = hostPlatform.uname.processor;

  sha256 = {
    aarch64 = "sha256-RXYiKKqD3ta75TKSwd59BqsdjDVlVXyqSqbOwo9QAIg=";
    x86_64 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  }.${arch};

in
stdenv.mkDerivation rec {
  pname = "firecracker";
  version = "0.25.0";

  src = fetchurl {
    url = "https://github.com/firecracker-microvm/firecracker/releases/download/v${version}/${pname}-v${version}-${arch}.tgz";
    inherit sha256;
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cat *spec*
    mkdir -p $out/bin
    mv firecracker-* $out/bin/firecracker
    mv jailer-* $out/bin/jailer
    chmod +x $out/bin/firecracker
  '';
}
