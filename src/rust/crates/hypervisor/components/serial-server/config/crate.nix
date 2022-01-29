{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-serial-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    hypervisor-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
