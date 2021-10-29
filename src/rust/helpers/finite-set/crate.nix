{ mk, localCrates }:

mk {
  nix.name = "finite-set";
  nix.local.dependencies = with localCrates; [
    finite-set-derive
  ];
  dependencies = {
  };
}
