{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-event-server-config";
  localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
