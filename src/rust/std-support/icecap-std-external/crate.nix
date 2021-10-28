{ mk, localCrates }:

mk {
  nix.name = "icecap-std-external";
  nix.localDependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
  };
}
