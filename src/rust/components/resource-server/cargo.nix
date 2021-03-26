{ mkBin, localCrates, serdeMin }:

mkBin {
  name = "resource-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-resource-server-types
    icecap-resource-server-config
    icecap-resource-server-core
    dyndl-types
  ];
  dependencies = {
    pinecone = "*";
    serde = serdeMin;
  };
}
