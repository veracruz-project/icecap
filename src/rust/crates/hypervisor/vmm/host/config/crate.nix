{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-host-vmm-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    hypervisor-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
