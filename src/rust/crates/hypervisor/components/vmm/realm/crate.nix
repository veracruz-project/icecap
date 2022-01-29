{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-realm-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    hypervisor-realm-vmm-config
    icecap-std
    hypervisor-vmm-core
    hypervisor-event-server-types
  ];
  nix.passthru.excludeFromDocs = true;
}
