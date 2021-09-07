{ mk, localCrates }:

mk {
  nix.name = "icecap-core";
  nix.localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-sync
    icecap-ring-buffer
    icecap-rpc
    icecap-rpc-sel4
    icecap-config
    icecap-backtrace
    icecap-failure
    icecap-logger
    icecap-start

    # HACK
    finite-set
    biterate
  ];
  nix.localDependencyAttributes = {
    icecap-sel4.features = [
      "use-serde"
    ];
    icecap-runtime.features = [
      "use-serde"
    ];
  };
}
