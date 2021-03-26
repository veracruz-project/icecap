{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-resource-server-config";
  localDependencies = with localCrates; [
    icecap-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
