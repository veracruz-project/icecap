{ mk, localCrates }:

mk {
  nix.name = "crosvm-9p";
  nix.localDependencies = with localCrates; [
    crosvm-9p-wire-format-derive
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
