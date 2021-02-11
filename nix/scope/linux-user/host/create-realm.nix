{ buildRustPackageIncrementally
, globalCrates
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = create-realm;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
