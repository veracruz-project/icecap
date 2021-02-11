{ buildRustPackageIncrementally
, globalCrates
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = serialize-runtime-config;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
