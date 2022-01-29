{ mkSeL4, localCrates, serdeMin }:

mkSeL4 {
  nix.name = "icecap-generic-serial-server-core";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-generic-timer-server-client
    icecap-driver-interfaces

    # TODO see note in timer-server/crate.nix
    icecap-pl011-driver
    icecap-bcm2835-aux-uart-driver
  ];
  dependencies = {
    cfg-if = "*";
    serde = serdeMin;
  };
}
