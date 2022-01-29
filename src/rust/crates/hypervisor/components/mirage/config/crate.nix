{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-mirage-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
