{ mkBin, localCrates }:

mkBin {
  name = "host-vmm";
  localDependencies = with localCrates; [
    biterate
    icecap-host-vmm-config
    icecap-std
    icecap-rpc-sel4
    icecap-vmm
    icecap-event-server-types
    icecap-resource-server-types
  ];
}
