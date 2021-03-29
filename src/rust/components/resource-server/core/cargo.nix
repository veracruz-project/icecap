{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-resource-server-core";
  localDependencies = with localCrates; [
    dyndl-types
    icecap-core
    icecap-resource-server-types
  ];
  dependencies = {
    log = "*";
    pinecone = "*";
    serde = serdeMin;
  };
}
