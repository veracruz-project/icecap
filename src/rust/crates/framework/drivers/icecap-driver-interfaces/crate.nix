{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-driver-interfaces";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
}
