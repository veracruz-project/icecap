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
}
