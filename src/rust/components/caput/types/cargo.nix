{ mk, serdeMin }:

mk {
  name = "icecap-caput-types";
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
