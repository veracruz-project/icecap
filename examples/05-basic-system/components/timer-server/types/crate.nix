{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "timer-server-types";
  nix.srcPath = ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-core
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
