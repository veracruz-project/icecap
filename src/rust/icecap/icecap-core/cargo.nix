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
    icecap-logger
    icecap-start
  ];
  localDependencyAttributes = {
    icecap-sel4.features = [
      "use-serde"
    ];
    icecap-runtime.features = [
      "use-serde"
    ];
  };
}
