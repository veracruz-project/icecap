{ mk, localCrates }:

mk {
  name = "icecap-failure";
  localDependencies = with localCrates; [
    icecap-failure-derive
    icecap-backtrace
    icecap-sel4
  ];
  dependencies = {
    log = "*";
    cfg-if = "*";
  };
}
