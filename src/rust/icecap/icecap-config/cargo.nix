{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-config";
  localDependencies = with localCrates; [
    icecap-config-sys
  ];
  dependencies = {
    serde = serdeMin;
  };
}
