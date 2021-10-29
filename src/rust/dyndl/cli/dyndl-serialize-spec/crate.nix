{ mkBin, localCrates }:

mkBin {
  nix.name = "dyndl-serialize-spec";
  nix.local.dependencies = with localCrates; [
    dyndl-types
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
