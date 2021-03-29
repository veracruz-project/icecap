{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-event-server-config";
  localDependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
