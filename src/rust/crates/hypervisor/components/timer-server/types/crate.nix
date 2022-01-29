{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-timer-server-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
