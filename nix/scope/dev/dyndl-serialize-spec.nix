{ buildRustPackageIncrementally
, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.dyndl-serialize-spec;
  layers =  [ [] ];

  debug = true;
}
