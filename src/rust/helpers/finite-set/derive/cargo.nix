{ mk, localCrates }:

mk {
  name = "finite-set-derive";
  lib.proc-macro = true;
  localDependencies = with localCrates; [
    finite-set-derive-impl
  ];
  dependencies = {
    synstructure = "0.12.0";
  };
}
