{ mk, localCrates }:

mk {
  name = "icecap-config-realize";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-interfaces
    icecap-config
  ];
}
