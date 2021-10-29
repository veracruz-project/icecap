{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "test";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependences = with globalCrates; [
    icecap-std
    icecap-start-generic
    icecap-benchmark-server-types
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
