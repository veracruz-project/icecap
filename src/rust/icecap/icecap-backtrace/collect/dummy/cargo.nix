{ mk, localCrates }:

mk {
  name = "icecap-backtrace-collect";
  localDependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    log = "*";
  };
}
