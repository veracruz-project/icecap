{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = create-realm;
  layers = [ [] ];

  debug = true;
  doCheck = false;
}
