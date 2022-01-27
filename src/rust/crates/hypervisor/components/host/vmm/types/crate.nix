{ mk, serdeMin, localCrates }:

mk {
  nix.name = "icecap-host-vmm-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
  nix.passthru.noDoc = true;
}
