{ mkComponent, localCrates }:

mkComponent {
  nix.name = "event-server";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-plat
    icecap-event-server-types
    icecap-event-server-config
  ];
}
