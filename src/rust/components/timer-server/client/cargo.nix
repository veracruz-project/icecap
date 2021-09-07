{ mk, localCrates }:

mk {
  nix.name = "icecap-timer-server-client";
  nix.localDependencies = with localCrates; [
    icecap-sel4
    icecap-rpc-sel4
    icecap-timer-server-types
  ];
}
