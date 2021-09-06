{ buildRustPackageIncrementally
, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.icecap-append-devices;
  layers = [ [] ];

  debug = true;
}
