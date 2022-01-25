{ buildRustPackageIncrementally
, callPackage
}:

buildRustPackageIncrementally rec {
  rootCrate = callPackage ./crate.nix {};
  debug = true;
}
