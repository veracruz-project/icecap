{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-benchmark-server-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
