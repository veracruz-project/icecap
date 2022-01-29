{ crateUtils, icecapSrc, globalCrates, timer-server-types }:

crateUtils.mkCrate {
  nix.name = "application";
  nix.isBin = true;
  nix.srcPath = ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-std
    icecap-start-generic
  ]) ++ [
    timer-server-types
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
