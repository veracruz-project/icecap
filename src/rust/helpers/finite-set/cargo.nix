{ mk, localCrates }:

mk {
  name = "finite-set";
  localDependencies = with localCrates; [
    finite-set-derive
  ];
  dependencies = {
  };
}
