{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-dlmalloc";
  nix.local.dependencies = with localCrates; [
    icecap-sync
  ];
  dependencies = {
    dlmalloc = "0.2.3";
  };
}
