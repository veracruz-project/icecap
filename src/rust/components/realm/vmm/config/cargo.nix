{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-realm-vmm-config";
  nix.localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
