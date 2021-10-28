{ mk, localCrates }:

mk {
  nix.name = "finite-set";
  nix.localDependencies = with localCrates; [
    finite-set-derive
  ];
  dependencies = {
  };
}
