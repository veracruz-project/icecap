{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-core
    icecap-vmm-gic
    icecap-event-server-types
  ];
  dependencies = {
    log = "*";
  };
}
