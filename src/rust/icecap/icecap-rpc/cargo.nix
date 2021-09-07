{ mk, serdeMin }:

mk {
  nix.name = "icecap-rpc";
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
