{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-host-cli;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
