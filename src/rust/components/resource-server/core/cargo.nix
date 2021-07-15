{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-resource-server-core";
  localDependencies = with localCrates; [
    dyndl-types
    icecap-core
    icecap-resource-server-types
    icecap-event-server-types
    icecap-timer-server-client
  ];
  dependencies = {
    log = "*";
    pinecone = "*";
    serde = serdeMin;
  };
}
