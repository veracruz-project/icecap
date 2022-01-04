{ mkComponent, localCrates }:

mkComponent {
  nix.name = "timer-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-drivers
    icecap-timer-server-types
    icecap-timer-server-config
  ];
  dependencies = {
    tock-registers = "*";
  };
}
