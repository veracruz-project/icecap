{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-host-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    hypervisor-host-vmm-config
    icecap-std
    hypervisor-vmm-core
    hypervisor-event-server-types
    hypervisor-resource-server-types
    hypervisor-benchmark-server-types
    hypervisor-host-vmm-types
  ];
  dependencies = {
    cfg-if = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
