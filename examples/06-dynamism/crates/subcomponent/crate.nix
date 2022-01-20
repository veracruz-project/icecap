{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "subcomponent";
  nix.isBin = true;
  nix.srcPath = icecapSrc.absolute ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
