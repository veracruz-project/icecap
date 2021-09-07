{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-timer-server-types";
  nix.localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
