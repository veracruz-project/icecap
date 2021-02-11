{ buildRustPackageIncrementally
, globalCrates
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = append-icecap-devices;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
