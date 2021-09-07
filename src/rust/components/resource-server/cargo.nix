{ mkBin, localCrates, serdeMin }:

mkBin {
  nix.name = "resource-server";
  nix.localDependencies = with localCrates; [
    icecap-std
    icecap-rpc-sel4
    icecap-event-server-types
    icecap-resource-server-types
    icecap-resource-server-config
    icecap-resource-server-core
    icecap-timer-server-client
    dyndl-types
  ];
  dependencies = {
    pinecone = "*";
    serde = serdeMin;
  };
}
