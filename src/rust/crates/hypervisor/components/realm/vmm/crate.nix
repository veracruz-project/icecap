{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "realm-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-realm-vmm-config
    icecap-std
    icecap-vmm
    icecap-event-server-types
  ];
  nix.passthru.excludeFromDocs = true;
}
