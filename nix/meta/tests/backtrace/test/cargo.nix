{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "test";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.localDependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
