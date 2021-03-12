{ mk, localCrates }:

mk {
  name = "icecap-core";
  localDependencies = with localCrates; [
    icecap-backtrace
    icecap-failure
    icecap-sel4-sys
    icecap-sel4
    icecap-sync
    icecap-runtime
    icecap-interfaces
    icecap-base-config-realize
    icecap-base-config
    icecap-start
  ];
}
