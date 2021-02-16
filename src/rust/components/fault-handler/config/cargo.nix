{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-fault-handler-config";
  localDependencies = with localCrates; [
    icecap-config-common
  ];
  dependencies = {
    serde = serdeMin;
  };
}
