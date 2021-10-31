{ mkSeL4, localCrates, serdeMin }:

mkSeL4 {
  nix.name = "icecap-resource-server-core";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    icecap-core
    icecap-plat
    icecap-resource-server-types
    icecap-event-server-types
    icecap-timer-server-client
  ];
  dependencies = {
    log = "*";
    pinecone = "*";
    serde = serdeMin;
  };
}