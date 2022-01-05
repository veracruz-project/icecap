{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "serial-server";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-drivers
    icecap-start-generic
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
