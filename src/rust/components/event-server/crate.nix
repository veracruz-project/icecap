{ mkComponent, localCrates }:

mkComponent {
  nix.name = "event-server";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-plat
    icecap-rpc-sel4
    icecap-event-server-types
    icecap-event-server-config
  ];
}
