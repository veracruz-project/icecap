{ mk, localCrates }:

mk {
  name = "icecap-core";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-sync
    icecap-interfaces
    icecap-base-config
    icecap-base-config-realize
    icecap-backtrace
    icecap-failure
    icecap-start
  ];
}
