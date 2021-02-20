{ mkBin, localCrates, serdeMin }:

mkBin {
  name = "caput";
  localDependencies = with localCrates; [
    icecap-std
    icecap-caput-types
    icecap-caput-config
    dyndl-types
    dyndl-realize
  ];
  dependencies = {
    pinecone = "*";
    serde = serdeMin;
  };
}
