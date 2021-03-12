{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-serial-server-config";
  localDependencies = with localCrates; [
    icecap-base-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
