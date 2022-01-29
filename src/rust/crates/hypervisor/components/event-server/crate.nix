{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-event-server";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-plat
    hypervisor-event-server-types
    hypervisor-event-server-config
  ];
  nix.passthru.excludeFromDocs = true;
}
