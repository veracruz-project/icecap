{ mk, localCrates }:

mk {
  name = "icecap-p9-server-linux";
  localDependencies = with localCrates; [
    icecap-p9
  ];
  dependencies = {
    libc = "*";
  };
  features.trace = [];
}
