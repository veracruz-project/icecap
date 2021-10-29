{ mk, localCrates }:

mk {
  nix.name = "crosvm-9p-server";
  nix.local.dependencies = with localCrates; [
    crosvm-9p
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
