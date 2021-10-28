{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-resource-server-config";
  nix.localDependencies = with localCrates; [
    icecap-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
