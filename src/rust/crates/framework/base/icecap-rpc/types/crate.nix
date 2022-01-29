{ mk, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-rpc-types";
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
