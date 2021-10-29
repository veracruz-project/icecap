{ mkBin, localCrates }:

mkBin {
  nix.name = "realm-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-realm-vmm-config
    icecap-std
    icecap-rpc-sel4
    icecap-vmm
    icecap-event-server-types
  ];
}
