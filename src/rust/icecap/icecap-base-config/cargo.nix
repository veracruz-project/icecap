{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-base-config";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  dependencies = {
    serde = serdeMin;
  };
}
