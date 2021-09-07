{ mk, localCrates }:

mk {
  nix.name = "crosvm-9p-server";
  nix.localDependencies = with localCrates; [
    crosvm-9p
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
