{ mk, localCrates }:

mk {
  name = "icecap-ring-buffer";
  localDependencies = with localCrates; [
    icecap-sel4
  ];
  dependencies = {
    log = "*";
    register = "*";
  };
}
