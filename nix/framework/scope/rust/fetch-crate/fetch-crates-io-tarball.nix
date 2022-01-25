{ fetchurl }:

{ name, version, sha256 } @ args:

fetchurl {
  name = "${name}-${version}.tar.gz";
  url = "https://crates.io/api/v1/crates/${name}/${version}/download";
  sha256 = sha256;
  passthru.crateMeta = args // {
    source = "crates-io";
  };
}
