{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-fault-handler-config";
  localDependencies = with localCrates; [
    icecap-base-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
