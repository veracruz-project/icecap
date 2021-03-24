{ mk, localCrates }:

mk {
  name = "icecap-timer-server-client";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-rpc-sel4
    icecap-timer-server-types
  ];
}
