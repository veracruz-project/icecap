{ mk, localCrates, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-resource-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc-types
  ];
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
  nix.passthru.noDoc = true;
}
