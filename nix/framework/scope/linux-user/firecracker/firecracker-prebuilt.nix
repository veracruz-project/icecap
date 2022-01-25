{ stdenv
, hostPlatform
, fetchurl
}:

let
  arch = hostPlatform.uname.processor;

  sha256 = {
    aarch64 = "sha256-75UC+HeVUfUk1HRvTJsOHbHHkgr6me1OtxDF7lahf68=";
  }.${arch};

in
stdenv.mkDerivation rec {
  pname = "firecracker";
  version = "0.25.2";

  src = fetchurl {
    url = "https://github.com/firecracker-microvm/firecracker/releases/download/v${version}/${pname}-v${version}-${arch}.tgz";
    inherit sha256;
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    install -D -t $out/doc *.yaml
    install -D -T firecracker-* $out/bin/firecracker
    install -D -T jailer-* $out/bin/jailer
  '';
}
