{ mkSeL4Bin, localCrates, serdeMin, postcardCommon }:

mkSeL4Bin {
  nix.name = "hypervisor-resource-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    hypervisor-event-server-types
    hypervisor-resource-server-types
    hypervisor-resource-server-config
    hypervisor-resource-server-core
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
