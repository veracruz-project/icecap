{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-pl011-driver";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-driver-interfaces
  ];
  dependencies = {
    tock-registers = "*";
  };
}
