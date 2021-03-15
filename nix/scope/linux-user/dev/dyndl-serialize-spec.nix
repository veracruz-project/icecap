{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = dyndl-serialize-spec;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
