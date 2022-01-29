{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-host-vmm-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
