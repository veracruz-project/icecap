{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-host-vmm-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
