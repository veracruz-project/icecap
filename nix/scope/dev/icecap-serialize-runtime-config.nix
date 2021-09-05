{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-serialize-runtime-config;
  layers =  [ [] ];

  debug = true;
}
