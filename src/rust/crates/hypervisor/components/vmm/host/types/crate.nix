{ mk, serdeMin, localCrates }:

mk {
  nix.name = "hypervisor-host-vmm-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
