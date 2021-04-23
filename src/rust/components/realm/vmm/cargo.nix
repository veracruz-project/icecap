{ mkBin, localCrates }:

mkBin {
  name = "realm-vmm";
  localDependencies = with localCrates; [
    biterate
    icecap-realm-vmm-config
    icecap-std
    icecap-rpc-sel4
    icecap-vmm
  ];
}
