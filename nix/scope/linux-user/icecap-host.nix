{ buildRustPackageIncrementally, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.icecap-host;
  layers = [ [] ];

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
}
