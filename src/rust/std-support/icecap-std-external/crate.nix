{ mkExclude, localCrates }:

mkExclude {
  nix.name = "icecap-std-external";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
  };
}
