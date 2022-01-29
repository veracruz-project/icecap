{ mk, serdeMin, localCrates }:

mk {
  nix.name = "icecap-host-vmm-types";
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
