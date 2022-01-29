{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "benchmark-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-plat
    icecap-benchmark-server-types
    icecap-benchmark-server-config
  ];
  dependencies = {
    cfg-if = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
