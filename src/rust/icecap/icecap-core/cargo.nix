{ mk, localCrates }:

mk {
  name = "icecap-core";
  localDependencies = with localCrates; [
    icecap-backtrace
    icecap-failure
    icecap-sel4-sys
    icecap-sel4
    icecap-runtime
    icecap-interfaces
    icecap-realize-config
    icecap-config-common
    icecap-start
  ];
}
