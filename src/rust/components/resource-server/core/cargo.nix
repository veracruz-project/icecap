{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-resource-server-core";
  localDependencies = with localCrates; [
    dyndl-types
    icecap-core
  ];
  dependencies = {
    log = "*";
    pinecone = "*";
    serde = serdeMin;
  };
}
