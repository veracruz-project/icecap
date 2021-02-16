{ mk, localCrates }:

mk {
  name = "icecap-vmm-core";
  localDependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-interfaces
  ];
  dependencies = {
    num = { version = "*"; default-features = false; };
    register = "*";
    log = "*";
  };
}
