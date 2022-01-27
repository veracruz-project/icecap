{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-resource-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    dyndl-types
    dyndl-realize-simple-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
