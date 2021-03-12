{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = append-icecap-devices;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
