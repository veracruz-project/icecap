{ buildRustPackageIncrementally
, outerGlobalCrates
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-serialize-event-server-out-index;
  layers =  [ [] ];

  debug = true;
}
