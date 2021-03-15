{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-serial-server-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
