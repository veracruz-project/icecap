{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = serialize-runtime-config;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
