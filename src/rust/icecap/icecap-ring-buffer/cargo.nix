{ mk, localCrates }:

mk {
  name = "icecap-ring-buffer";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-config
  ];
  dependencies = {
    log = "*";
    tock-registers = "0.5";
  };
}
