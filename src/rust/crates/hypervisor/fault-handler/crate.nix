{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "fault-handler";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-fault-handler-config
  ];
  nix.passthru.excludeFromDocs = true;
}
