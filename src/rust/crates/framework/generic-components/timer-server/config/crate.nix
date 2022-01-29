{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-generic-timer-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
