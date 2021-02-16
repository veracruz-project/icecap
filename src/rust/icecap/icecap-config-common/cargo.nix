{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-config-common";
  localDependencies = with localCrates; [
    icecap-sel4-hack
  ];
  dependencies = {
    serde = serdeMin;
  };
}
