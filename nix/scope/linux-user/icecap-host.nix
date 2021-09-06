{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-host;
  layers = [ [] ];

  debug = false;

  extraManifest = {
    profile.release = {
      codegen-units = 1;
      opt-level = 3;
      lto = true;
    };
  };

  extraCargoConfig = {
    target.aarch64-unknown-linux-musl.rustflags = [
      "-C" "link-arg=-lgcc"
    ];
  };

  extraArgs = {
  RUST_BACKTRACE="full";
  };
}
