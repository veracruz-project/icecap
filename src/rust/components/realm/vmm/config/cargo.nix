{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-realm-vmm-config";
  localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
