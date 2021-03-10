{ mk, localCrates }:

mk {
  name = "icecap-backtrace";
  localDependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    log = "*";
  };
}
