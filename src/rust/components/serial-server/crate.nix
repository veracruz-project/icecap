{ mkBin, localCrates, serdeMin }:

mkBin {
  nix.name = "serial-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-serial-server-config
    icecap-timer-server-client
    icecap-event-server-types
  ];
  dependencies = {
    tock-registers = "*";
    serde = serdeMin;
  };
}
