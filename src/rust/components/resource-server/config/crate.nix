{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-resource-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
