{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "supercomponent";
  nix.isBin = true;
  nix.srcPath = ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
    dyndl-types
    dyndl-realize
    dyndl-realize-simple
    dyndl-realize-simple-config
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
    postcard = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
}
