{ mkLinuxBin, localCrates, postcardCommon }:

mkLinuxBin {
  nix.name = "icecap-serialize-generic-component-config";
  nix.local.dependencies = with localCrates; [
    icecap-config-cli-core

    icecap-generic-timer-server-config
  ];

  dependencies = {
    serde = "*";
    serde_json = "*";
    postcard = postcardCommon;
  };
  nix.passthru.excludeFromDocs = true;
}
