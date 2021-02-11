{ buildRustPackageIncrementally
, globalCrates
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = show-backtrace;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
