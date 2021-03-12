{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-timer-server-config";
  localDependencies = with localCrates; [
    icecap-base-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
