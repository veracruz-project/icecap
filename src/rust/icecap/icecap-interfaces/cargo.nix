{ mk, localCrates }:

mk {
  name = "icecap-interfaces";
  localDependencies = with localCrates; [
    icecap-sel4
  ];
  dependencies = {
    log = "*";
    register = "*";
  };
}
