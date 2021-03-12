{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = serialize-dyndl-spec;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
