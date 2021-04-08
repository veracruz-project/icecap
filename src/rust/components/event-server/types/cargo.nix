{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-event-server-types";
  localDependencies = with localCrates; [
    finite-set
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
  };
}
