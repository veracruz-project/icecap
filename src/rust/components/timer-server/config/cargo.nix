{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-timer-server-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
