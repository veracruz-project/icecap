{ mk, localCrates }:

mk {
  name = "icecap-core";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-sync
    icecap-ring-buffer
    icecap-config
    icecap-backtrace
    icecap-failure
    icecap-start
  ];
}
