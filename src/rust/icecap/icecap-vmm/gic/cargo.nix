{ mk, localCrates }:

mk {
  name = "icecap-vmm-gic";
  localDependencies = with localCrates; [
    biterate
    icecap-sel4
    icecap-failure
  ];
  dependencies = {
    log = "*";
  };
}