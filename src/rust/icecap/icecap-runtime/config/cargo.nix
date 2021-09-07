{ mk, serdeMin }:

mk {
  nix.name = "icecap-runtime-config";
  dependencies = {
    serde = serdeMin;
  };
}
