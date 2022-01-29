{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "host-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-host-vmm-config
    icecap-std
    hypervisor-vmm-core
    icecap-event-server-types
    icecap-resource-server-types
    icecap-benchmark-server-types
    icecap-host-vmm-types
  ];
  dependencies = {
    cfg-if = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
