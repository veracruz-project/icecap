{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "event-server";
  nix.local.dependencies = with localCrates; [
    biterate
    finite-set
    icecap-std
    icecap-plat
    icecap-event-server-types
    icecap-event-server-config
  ];
  nix.passthru.excludeFromDocs = true;
}
