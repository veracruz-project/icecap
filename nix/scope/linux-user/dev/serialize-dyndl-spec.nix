{ buildRustPackageIncrementally
, globalCrates
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = serialize-dyndl-spec;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
