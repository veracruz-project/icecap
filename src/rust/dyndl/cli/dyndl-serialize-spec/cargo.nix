{ mkBin, localCrates }:

mkBin {
  nix.name = "dyndl-serialize-spec";
  nix.localDependencies = with localCrates; [
    dyndl-types
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
