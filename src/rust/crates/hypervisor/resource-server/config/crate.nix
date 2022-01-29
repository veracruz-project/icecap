{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-resource-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    dyndl-types
    dyndl-realize-simple-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
