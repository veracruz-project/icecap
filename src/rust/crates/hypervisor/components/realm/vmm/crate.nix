{ mkComponent, localCrates }:

mkComponent {
  nix.name = "realm-vmm";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-realm-vmm-config
    icecap-std
    icecap-vmm
    icecap-event-server-types
  ];
}
