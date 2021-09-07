{ mkBin, localCrates }:

mkBin {
  nix.name = "event-server";
  nix.localDependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-rpc-sel4
    icecap-event-server-types
    icecap-event-server-config
  ];
}
