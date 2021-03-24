{ mkBin, localCrates }:

mkBin {
  name = "timer-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-rpc-sel4
    icecap-timer-server-types
    icecap-timer-server-config
  ];
  dependencies = {
    register = "*";
  };
}
