{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-std-external";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
  };
}
