{ mkSeL4, localCrates, serdeMin }:

mkSeL4 {
  nix.name = "icecap-start";
  nix.local.dependencies = with localCrates; [
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
