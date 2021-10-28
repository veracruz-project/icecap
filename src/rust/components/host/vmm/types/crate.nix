{ mk, serdeMin, localCrates }:

mk {
  nix.name = "icecap-host-vmm-types";
  nix.localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
