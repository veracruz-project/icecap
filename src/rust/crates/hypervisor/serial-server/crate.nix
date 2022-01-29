{ mkSeL4Bin, localCrates, serdeMin }:

mkSeL4Bin {
  nix.name = "hypervisor-serial-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    hypervisor-serial-server-config
    icecap-generic-timer-server-client
    icecap-generic-serial-server-core
    hypervisor-event-server-types
    icecap-driver-interfaces
    finite-set

    # TODO see note in timer-server/crate.nix
    icecap-pl011-driver
    icecap-bcm2835-aux-uart-driver
  ];
  dependencies = {
    cfg-if = "*";
    tock-registers = "*";
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
