{ mkSeL4Bin, localCrates, serdeMin, postcardCommon }:

mkSeL4Bin {
  nix.name = "resource-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-event-server-types
    icecap-resource-server-types
    icecap-resource-server-config
    icecap-resource-server-core
    icecap-generic-timer-server-client
    dyndl-types
    dyndl-realize
    dyndl-realize-simple
    dyndl-realize-simple-config
  ];
  dependencies = {
    postcard = postcardCommon;
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
