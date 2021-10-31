{ mk, serdeMin, localCrates }:

mk {
  nix.name = "icecap-resource-server-types";
  nix.local.dependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
    serde = serdeMin;
    pinecone = "*";
  };
}
