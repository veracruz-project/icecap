{ mk, localCrates }:

mk {
  name = "icecap-base-config-realize";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-interfaces
    icecap-base-config
  ];
}
