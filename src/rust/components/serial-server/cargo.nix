{ mkBin, localCrates, serdeMin }:

mkBin {
  name = "serial-server";
  localDependencies = with localCrates; [
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
