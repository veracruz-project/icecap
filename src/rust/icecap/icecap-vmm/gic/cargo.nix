{ mk, localCrates }:

mk {
  nix.name = "icecap-vmm-gic";
  nix.localDependencies = with localCrates; [
    biterate
    icecap-sel4
    icecap-failure
    icecap-failure-derive
  ];
  dependencies = {
    log = "*";
  };
}
