{ mk, localCrates }:

mk {
  nix.name = "icecap-rpc-sel4";
  nix.localDependencies = with localCrates; [
    icecap-sel4
    icecap-rpc
  ];
}
