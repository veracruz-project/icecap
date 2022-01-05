{ mkBin, localCrates, postcardCommon }:

mkBin {
  nix.name = "icecap-serialize-builtin-config";
  nix.local.dependencies = with localCrates; [
    icecap-config-cli-core

    icecap-fault-handler-config
    icecap-timer-server-config
    icecap-serial-server-config
    icecap-host-vmm-config
    icecap-realm-vmm-config
    icecap-resource-server-config
    icecap-event-server-config
    icecap-benchmark-server-config
    icecap-mirage-config
  ];

  dependencies = {
    serde = "*";
    serde_json = "*";
    postcard = postcardCommon;
  };
}
