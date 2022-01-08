{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "serial-server";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-start-generic
    icecap-driver-interfaces
    icecap-pl011-driver
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
