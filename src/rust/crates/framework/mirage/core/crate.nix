{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-mirage-core";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-linux-syscall-types
    icecap-linux-syscall-musl
  ];
}
