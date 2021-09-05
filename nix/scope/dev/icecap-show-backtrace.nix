{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-show-backtrace;
  layers =  [ [] ];

  debug = true;
}
