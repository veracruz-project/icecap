{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-idle";
  nix.local.dependencies = with localCrates; [
    icecap-std
  ];
  dependencies = {
    cortex-a = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
