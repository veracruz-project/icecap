{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-runtime";
  localDependencies = with localCrates; [
    icecap-sel4
  ];
  dependencies = {
    serde = serdeMin;
  };
}
