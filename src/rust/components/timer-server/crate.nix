{ mkComponent, localCrates }:

mkComponent {
  nix.name = "timer-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-rpc-sel4
    icecap-timer-server-types
    icecap-timer-server-config
  ];
  dependencies = {
    tock-registers = "*";
  };
}
