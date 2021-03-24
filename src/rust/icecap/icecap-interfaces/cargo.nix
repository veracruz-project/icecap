{ mk, localCrates }:

mk {
  name = "icecap-interfaces";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-timer-server-client
  ];
  dependencies = {
    log = "*";
    register = "*";
  };
}
