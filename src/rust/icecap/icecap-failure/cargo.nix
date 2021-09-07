{ mk, localCrates }:

mk {
  nix.name = "icecap-failure";
  nix.localDependencies = with localCrates; [
    icecap-failure-derive
    icecap-backtrace
    icecap-sel4
  ];
  dependencies = {
    log = "*";
    cfg-if = "*";
  };
}
