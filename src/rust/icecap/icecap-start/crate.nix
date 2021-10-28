{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-start";
  nix.localDependencies = with localCrates; [
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
