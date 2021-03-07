{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-caput-core";
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
