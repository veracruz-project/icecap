{ mkBin, localCrates }:

mkBin {
  name = "timer-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-timer-server-config
  ];
  dependencies = {
    register = "*";
  };
}
