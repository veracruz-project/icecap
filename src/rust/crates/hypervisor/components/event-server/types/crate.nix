{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-event-server-types";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
