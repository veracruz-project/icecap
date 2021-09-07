{ mk }:

mk {
  nix.name = "icecap-config-cli-core";
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
