{ mk, serdeMin, localCrates }:

mk {
  name = "icecap-resource-server-types";
  localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
