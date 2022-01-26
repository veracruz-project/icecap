{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "test";
  nix.isBin = true;
  nix.srcPath = icecapSrc.absolute ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
    icecap-benchmark-server-types
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
