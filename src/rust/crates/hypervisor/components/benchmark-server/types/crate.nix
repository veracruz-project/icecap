{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-benchmark-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
