{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-timer-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
