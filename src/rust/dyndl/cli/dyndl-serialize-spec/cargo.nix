{ mkBin, localCrates }:

mkBin {
  name = "dyndl-serialize-spec";
  localDependencies = with localCrates; [
    dyndl-types
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
