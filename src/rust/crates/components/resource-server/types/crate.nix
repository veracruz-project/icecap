{ mk, localCrates, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-resource-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
