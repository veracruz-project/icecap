{ stdenv
, hostPlatform
, fetchurl
}:

let
  arch = hostPlatform.uname.processor;

  sha256 = {
    aarch64 = "1kb14g5z9jmd0mvshv2wd6s6isqdndpqywzm4xifw30csvp0ln0a";
    x86_64 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  }.${arch};

in
stdenv.mkDerivation rec {
  pname = "firecracker";
  version = "0.21.0";

  binary = fetchurl {
    url = "https://github.com/firecracker-microvm/firecracker/releases/download/v${version}/${pname}-v${version}-${arch}";
    inherit sha256;
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp $binary $out/bin/firecracker
    chmod +x $out/bin/firecracker
  '';
}
