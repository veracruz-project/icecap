{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-vmm-config";
  localDependencies = with localCrates; [
    icecap-sel4-hack # HACK
    icecap-config-common
  ];
  dependencies = {
    serde = serdeMin;
  };
}
