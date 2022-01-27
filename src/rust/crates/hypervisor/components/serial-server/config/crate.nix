{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-serial-server-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
