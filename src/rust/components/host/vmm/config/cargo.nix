{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-host-vmm-config";
  nix.localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
