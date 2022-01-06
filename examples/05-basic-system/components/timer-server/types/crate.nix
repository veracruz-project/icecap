{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "timer-server-types";
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-core
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
