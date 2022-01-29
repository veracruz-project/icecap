{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "idle";
  nix.local.dependencies = with localCrates; [
    icecap-std
  ];
  dependencies = {
    cortex-a = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
