{ mkLinuxBin, localCrates, postcardCommon }:

mkLinuxBin {
  nix.name = "hypervisor-serialize-component-config";
  nix.local.dependencies = with localCrates; [
    icecap-config-cli-core

    hypervisor-fault-handler-config
    hypervisor-serial-server-config
    hypervisor-host-vmm-config
    hypervisor-realm-vmm-config
    hypervisor-resource-server-config
    hypervisor-event-server-config
    hypervisor-benchmark-server-config
    hypervisor-mirage-config
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    postcard = postcardCommon;
  };
  nix.passthru.excludeFromDocs = true;
}
