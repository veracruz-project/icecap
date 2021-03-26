{ mk, serdeMin }:

mk {
  name = "icecap-resource-server-types";
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
