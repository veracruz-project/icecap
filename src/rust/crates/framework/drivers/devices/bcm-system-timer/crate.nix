{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-bcm-system-timer-driver";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-driver-interfaces
  ];
  dependencies = {
    tock-registers = "*";
  };
}
