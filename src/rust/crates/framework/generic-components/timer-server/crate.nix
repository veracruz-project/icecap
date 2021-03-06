{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "icecap-generic-timer-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-generic-timer-server-types
    icecap-generic-timer-server-config

    icecap-driver-interfaces

    # TODO
    # We should only incur dependencies relevant to the platform.
    # target.'cfg(...)'.dependencies is limited and does not see our icecap_plat
    # value.  It may the case that, for now, features corresponding to platforms
    # is the only way to do this.
    icecap-virt-timer-driver
    icecap-bcm-system-timer-driver
  ];
  dependencies = {
    cfg-if = "*";
    tock-registers = "*";
  };
}
