{ buildRustPackageIncrementally
, callPackage
}:

buildRustPackageIncrementally rec {
  rootCrate = callPackage ./cargo.nix {};
  layers = [ [] ];

  debug = true;
}
