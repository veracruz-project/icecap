{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-realm-vmm-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
