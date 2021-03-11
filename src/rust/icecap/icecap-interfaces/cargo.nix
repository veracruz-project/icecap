{ mk, localCrates }:

mk {
  name = "icecap-interfaces";
  localDependencies = with localCrates; [
    icecap-failure
    icecap-sel4
  ];
  dependencies = {
    log = "*";
    register = "*";
  };
}