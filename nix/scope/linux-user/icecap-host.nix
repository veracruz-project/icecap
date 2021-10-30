{ buildRustPackageIncrementally, globalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = globalCrates.icecap-host;
  layers = [ [] ];

  extraManifest = {
    profile.release = {
      codegen-units = 1;
      lto = true;
    };
  };
}
