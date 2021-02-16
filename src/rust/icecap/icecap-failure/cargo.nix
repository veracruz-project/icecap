{ mk, localCrates }:

mk {
  name = "icecap-failure";
  localDependencies = with localCrates; [
    icecap-backtrace
    icecap-failure-derive
  ];
  dependencies = {
    log = "*";
    cfg-if = "*";
  };
}
