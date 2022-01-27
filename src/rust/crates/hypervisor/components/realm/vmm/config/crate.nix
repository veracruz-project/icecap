{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-realm-vmm-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.hack.noDoc = true;
}
