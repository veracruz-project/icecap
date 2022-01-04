{ mkComponent, localCrates, serdeMin, postcardCommon }:

mkComponent {
  nix.name = "resource-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-event-server-types
    icecap-resource-server-types
    icecap-resource-server-config
    icecap-resource-server-core
    icecap-timer-server-client
    dyndl-types
  ];
  dependencies = {
    postcard = postcardCommon;
    serde = serdeMin;
  };
}
