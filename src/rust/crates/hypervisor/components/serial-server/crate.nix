{ mkComponent, localCrates, serdeMin }:

mkComponent {
  nix.name = "serial-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-drivers
    icecap-serial-server-config
    icecap-timer-server-client
    icecap-event-server-types
  ];
  dependencies = {
    tock-registers = "*";
    serde = serdeMin;
  };
}
