{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "hypervisor-resource-server-core";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    dyndl-realize
    icecap-core
    icecap-plat
    hypervisor-resource-server-types
    hypervisor-event-server-types
    icecap-generic-timer-server-client
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
    postcard = postcardCommon;
  };
  nix.passthru.excludeFromDocs = true;
}
