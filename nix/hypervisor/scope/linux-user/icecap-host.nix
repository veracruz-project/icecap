{ buildRustPackageIncrementally, globalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = globalCrates.icecap-host;
  extraManifest = {
    profile.release = {
      codegen-units = 1;
      lto = true;
    };
  };
}
