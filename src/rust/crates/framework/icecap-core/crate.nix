{ mkSeL4, localCrates }:

mkSeL4 {
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
  dependencies = {
    icecap-sel4.features = [
      "serde1"
    ];
    icecap-runtime.features = [
      "serde1"
    ];
  };
}
