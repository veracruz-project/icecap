{ mk, localCrates }:

mk {
  name = "crosvm-9p-server";
  localDependencies = with localCrates; [
    crosvm-9p
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
