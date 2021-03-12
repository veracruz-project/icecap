{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-vmm-config";
  localDependencies = with localCrates; [
    icecap-base-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
