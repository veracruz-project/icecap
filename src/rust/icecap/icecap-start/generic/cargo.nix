{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-start-generic";
  localDependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-runtime
    icecap-start
  ];
  dependencies = {
    log = "*"; # TODO
    pinecone = "*";
    serde = serdeMin;
    serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
}
