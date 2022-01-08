{ mkComponent, localCrates, serdeMin }:

mkComponent {
  nix.name = "serial-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-serial-server-config
    icecap-timer-server-client
    icecap-event-server-types

    icecap-driver-interfaces

    # TODO see note in timer-server/crate.nix
    icecap-pl011-driver
    icecap-bcm2835-aux-uart-driver
  ];
  dependencies = {
    cfg-if = "*";
    tock-registers = "*";
    serde = serdeMin;
  };
}
