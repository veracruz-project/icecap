{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-fault-handler-config";
  nix.localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
