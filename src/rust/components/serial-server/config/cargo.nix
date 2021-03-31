{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-serial-server-config";
  localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
