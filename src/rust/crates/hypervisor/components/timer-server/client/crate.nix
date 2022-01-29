{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-timer-server-client";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-rpc
    icecap-timer-server-types
  ];
  nix.passthru.noDoc = true;
}
