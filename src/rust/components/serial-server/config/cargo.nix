{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-serial-server-config";
  localDependencies = with localCrates; [
    icecap-config-common
  ];
  dependencies = {
    serde = serdeMin;
  };
}
