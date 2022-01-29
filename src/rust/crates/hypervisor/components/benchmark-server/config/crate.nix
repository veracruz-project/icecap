{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-benchmark-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
