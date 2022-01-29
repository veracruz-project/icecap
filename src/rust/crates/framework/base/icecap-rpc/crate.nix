{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-rpc";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-rpc-types
  ];
}
