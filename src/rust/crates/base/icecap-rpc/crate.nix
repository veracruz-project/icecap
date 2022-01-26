{ mk, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-rpc";
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
