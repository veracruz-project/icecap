{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-host;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
