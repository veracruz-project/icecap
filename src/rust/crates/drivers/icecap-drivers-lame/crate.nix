{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-drivers";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    tock-registers = "*";
  };
}
