{ mk, localCrates }:

mk {
  nix.name = "icecap-core";
  nix.local.dependencies = with localCrates; [
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
  nix.localAttrs.dependencies = {
    icecap-sel4.features = [
      "use-serde"
    ];
    icecap-runtime.features = [
      "use-serde"
    ];
  };
}
