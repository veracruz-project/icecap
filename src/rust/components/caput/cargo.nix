{ mkBin, localCrates, serdeMin }:

mkBin {
  name = "caput";
  localDependencies = with localCrates; [
    icecap-std
    icecap-caput-types
    icecap-caput-config
    icecap-caput-core
    dyndl-types
  ];
  dependencies = {
    pinecone = "*";
    serde = serdeMin;
  };
}
