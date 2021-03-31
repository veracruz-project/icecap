{ mkBin, localCrates }:

mkBin {
  name = "serial-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-serial-server-config
    icecap-timer-server-client
    icecap-event-server-types
  ];
  dependencies = {
    register = "*";
  };
}
