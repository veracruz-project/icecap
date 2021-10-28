{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-serial-server-config";
  nix.localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}