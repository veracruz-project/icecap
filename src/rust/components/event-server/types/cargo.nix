{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-event-server-types";
  nix.localDependencies = with localCrates; [
    finite-set
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
