{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "minimal";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
