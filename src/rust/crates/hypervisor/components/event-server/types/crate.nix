{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-event-server-types";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
