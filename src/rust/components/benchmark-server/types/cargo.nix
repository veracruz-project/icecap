{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-benchmark-server-types";
  nix.localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
