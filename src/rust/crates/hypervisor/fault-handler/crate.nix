{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-fault-handler";
  nix.local.dependencies = with localCrates; [
    icecap-std
    hypervisor-fault-handler-config
  ];
  nix.passthru.excludeFromDocs = true;
}
