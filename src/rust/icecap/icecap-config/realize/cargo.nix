{ mk, localCrates }:

mk {
  name = "icecap-config-realize";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-ring-buffer
    icecap-config
  ];
}
