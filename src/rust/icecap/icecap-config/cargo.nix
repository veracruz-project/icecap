{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-config";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  dependencies = {
    serde = serdeMin;
  };
}
