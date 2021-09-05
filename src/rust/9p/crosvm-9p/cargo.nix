{ mk, localCrates }:

mk {
  name = "crosvm-9p";
  localDependencies = with localCrates; [
    crosvm-9p-wire-format-derive
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
