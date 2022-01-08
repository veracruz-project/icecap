{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-virt-timer-driver";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-driver-interfaces
  ];
  dependencies = {
    tock-registers = "*";
  };
}
