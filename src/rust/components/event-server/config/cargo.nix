{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-event-server-config";
  nix.localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
