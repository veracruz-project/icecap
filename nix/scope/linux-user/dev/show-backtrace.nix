{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = show-backtrace;
  layers =  [ [] ];

  debug = true;
  doCheck = false;
}
