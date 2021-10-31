{ mkSeL4, localCrates, patches }:

mkSeL4 {
  nix.name = "icecap-std";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
    dlmalloc = patches.dlmalloc.dep;
  };
}
