{ mk, localCrates }:

mk {
  name = "icecap-std-external";
  localDependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
  };
}
