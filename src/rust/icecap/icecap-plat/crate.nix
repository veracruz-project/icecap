{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-plat";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
  ];
  dependencies = {
    cfg-if = "*";
  };
}
