{ mkBin, localCrates }:

mkBin {
  name = "serialize-dyndl-spec";
  localDependencies = with localCrates; [
    dyndl-types
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    pinecone = "*";
  };
}
