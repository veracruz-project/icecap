{ mk }:

mk {
  name = "icecap-serialize-config";
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
