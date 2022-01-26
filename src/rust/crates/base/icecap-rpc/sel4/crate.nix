{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-rpc-sel4";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-rpc
  ];
}
