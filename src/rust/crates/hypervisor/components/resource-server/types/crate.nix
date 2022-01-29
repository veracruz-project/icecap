{ mk, localCrates, serdeMin, postcardCommon }:

mk {
  nix.name = "hypervisor-resource-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc-types
  ];
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
  nix.passthru.excludeFromDocs = true;
}
