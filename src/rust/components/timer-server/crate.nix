{ mkBin, localCrates }:

mkBin {
  nix.name = "timer-server";
  nix.localDependencies = with localCrates; [
    icecap-std
    icecap-rpc-sel4
    icecap-timer-server-types
    icecap-timer-server-config
  ];
  dependencies = {
    tock-registers = "*";
  };
}