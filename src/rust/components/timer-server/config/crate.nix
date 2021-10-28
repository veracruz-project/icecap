{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-timer-server-config";
  nix.localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
