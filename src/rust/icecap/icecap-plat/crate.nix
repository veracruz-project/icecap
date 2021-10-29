{ mk, localCrates }:

mk {
  nix.name = "icecap-plat";
  nix.localDependencies = with localCrates; [
    icecap-sel4
  ];
  dependencies = {
    cfg-if = "*";
  };
}
