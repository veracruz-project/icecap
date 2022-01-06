{ buildRustPackageIncrementally
, callPackage
}:

buildRustPackageIncrementally rec {
  rootCrate = callPackage ./cargo.nix {};
  debug = true;
}
