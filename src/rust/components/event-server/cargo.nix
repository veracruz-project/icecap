{ mkBin, localCrates }:

mkBin {
  name = "event-server";
  localDependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-rpc-sel4
    icecap-event-server-types
    icecap-event-server-config
  ];
}
