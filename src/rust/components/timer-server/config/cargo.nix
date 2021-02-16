{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-timer-server-config";
  localDependencies = with localCrates; [
    icecap-config-common
  ];
  dependencies = {
    serde = serdeMin;
  };
}
