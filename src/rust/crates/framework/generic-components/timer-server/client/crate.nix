{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-generic-timer-server-client";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-rpc
    icecap-generic-timer-server-types
  ];
  nix.passthru.excludeFromDocs = true;
}
