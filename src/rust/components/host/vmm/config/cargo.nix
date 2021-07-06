{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-host-vmm-config";
  localDependencies = with localCrates; [
    icecap-config
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
