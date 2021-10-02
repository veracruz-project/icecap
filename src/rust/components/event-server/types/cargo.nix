{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-event-server-types";
  nix.localDependencies = with localCrates; [
    biterate
    finite-set
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
