{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-start";
  localDependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-runtime
  ];
  dependencies = {
    log = "*"; # TODO
    pinecone = "*";
    serde = serdeMin;
  };
}