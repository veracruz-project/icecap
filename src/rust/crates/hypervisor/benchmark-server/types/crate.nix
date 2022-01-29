{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-benchmark-server-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
