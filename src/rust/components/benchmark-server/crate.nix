{ mkComponent, localCrates }:

mkComponent {
  nix.name = "benchmark-server";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-std
    icecap-plat
    icecap-rpc-sel4
    icecap-benchmark-server-types
    icecap-benchmark-server-config
  ];
}
