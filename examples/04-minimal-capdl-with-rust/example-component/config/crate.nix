{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "example-component-config";
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-config
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
