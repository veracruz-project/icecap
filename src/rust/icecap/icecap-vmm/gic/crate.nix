{ mk, localCrates }:

mk {
  nix.name = "icecap-vmm-gic";
  nix.local.dependencies = with localCrates; [
    biterate
    icecap-sel4
    icecap-failure
    icecap-failure-derive
  ];
  dependencies = {
    log = "*";
  };
}
