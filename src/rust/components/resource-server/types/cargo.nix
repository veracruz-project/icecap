{ mk, serdeMin, localCrates }:

mk {
  name = "icecap-resource-server-types";
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
  localDependencies = with localCrates; [
    icecap-rpc
  ];
}
