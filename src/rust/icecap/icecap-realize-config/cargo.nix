{ mk, localCrates }:

mk {
  name = "icecap-realize-config";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-interfaces
    icecap-config-common
  ];
}
