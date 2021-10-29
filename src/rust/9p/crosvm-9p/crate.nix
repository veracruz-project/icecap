{ mk, localCrates }:

mk {
  nix.name = "crosvm-9p";
  nix.local.dependencies = with localCrates; [
    crosvm-9p-wire-format-derive
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
