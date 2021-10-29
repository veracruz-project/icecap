{ mkBin, localCrates }:

mkBin {
  nix.name = "host-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-host-vmm-config
    icecap-std
    icecap-rpc-sel4
    icecap-vmm
    icecap-event-server-types
    icecap-resource-server-types
    icecap-benchmark-server-types
    icecap-sel4
    icecap-host-vmm-types
  ];
}
