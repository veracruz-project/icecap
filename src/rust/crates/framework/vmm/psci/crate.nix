{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-vmm-psci";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
  ];
}
