{ mk, serdeMin }:

mk {
  name = "icecap-rpc";
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
