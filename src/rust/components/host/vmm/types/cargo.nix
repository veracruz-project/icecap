{ mk, serdeMin, localCrates }:

mk {
  name = "icecap-host-vmm-types";
  localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
