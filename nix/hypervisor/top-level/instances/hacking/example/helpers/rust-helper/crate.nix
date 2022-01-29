{ crateUtils, icecapSrc }:

crateUtils.mkCrate {
  nix.name = "rust-helper";
  nix.isBin = true;
  nix.srcPath = ./src;
}
