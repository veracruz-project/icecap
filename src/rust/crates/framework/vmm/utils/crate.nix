{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-vmm-utils";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-failure
    icecap-vmm-gic
  ];
}
