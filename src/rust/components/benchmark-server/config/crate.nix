{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-benchmark-server-config";
  nix.localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
