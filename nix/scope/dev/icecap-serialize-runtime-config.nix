{ buildRustPackageIncrementally
, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.icecap-serialize-runtime-config;
  layers =  [ [] ];

  debug = true;
}
