{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-vmm-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
