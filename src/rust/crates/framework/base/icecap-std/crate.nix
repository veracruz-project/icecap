{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-std";
  nix.local.dependencies = with localCrates; [
    icecap-core
    icecap-dlmalloc
  ];
  dependencies = {
    log = "*";
  };
}
