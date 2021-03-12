{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-vmm-config";
  localDependencies = with localCrates; [
    icecap-config-common
  ];
  dependencies = {
    serde = serdeMin;
  };
}
