{ buildRustPackageIncrementally
, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.icecap-show-backtrace;
  layers = [ [] ];

  debug = true;
}
