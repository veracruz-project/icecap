{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "hypervisor-vmm-core";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-core
    icecap-vmm-gic
    icecap-vmm-psci
    hypervisor-event-server-types
  ];
  dependencies = {
    log = "*";
  };
}
