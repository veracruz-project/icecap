{ mk, postcardCommon }:

mk {
  nix.name = "icecap-config-cli-core";
  dependencies = {
    serde = "*";
    serde_json = "*";
    postcard = postcardCommon;
  };
}
