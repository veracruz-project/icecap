{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-host;
  layers = [ [] ];

  debug = true;

  extraCargoConfig = {
    target.aarch64-unknown-linux-musl.rustflags = [
      "-C" "link-arg=-lgcc"
    ];
  };
}
