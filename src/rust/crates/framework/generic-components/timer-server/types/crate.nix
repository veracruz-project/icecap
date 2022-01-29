{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-generic-timer-server-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
