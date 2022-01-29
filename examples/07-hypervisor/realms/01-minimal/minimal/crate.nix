{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "minimal";
  nix.isBin = true;
  nix.srcPath = ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
