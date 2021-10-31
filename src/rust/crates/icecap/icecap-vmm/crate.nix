{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-sel4
    icecap-failure
    icecap-ring-buffer
    icecap-core
    icecap-rpc-sel4
    icecap-vmm-gic
    icecap-event-server-types
  ];
  dependencies = {
    log = "*";
  };
}
