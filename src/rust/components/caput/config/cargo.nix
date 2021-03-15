{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-caput-config";
  localDependencies = with localCrates; [
    icecap-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
