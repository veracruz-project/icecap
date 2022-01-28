{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-failure";
  nix.local.dependencies = with localCrates; [
    icecap-failure-derive
    icecap-backtrace
    icecap-sel4
  ];
  dependencies = {
    cfg-if = "*";
    log = "*";
  };
}
