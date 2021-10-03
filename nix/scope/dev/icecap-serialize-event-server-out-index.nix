{ buildRustPackageIncrementally
, outerGlobalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.icecap-serialize-event-server-out-index;
  layers = [ [] ];

  debug = true;
}
