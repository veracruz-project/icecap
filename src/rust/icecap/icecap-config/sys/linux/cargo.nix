{ mk, serdeMin }:

mk {
  nix.name = "icecap-config-sys";
  dependencies = {
    serde = serdeMin;
  };
}
