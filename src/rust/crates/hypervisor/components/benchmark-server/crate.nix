{ mkSeL4Bin, localCrates }:

mkSeL4Bin {
  nix.name = "hypervisor-benchmark-server";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-plat
    hypervisor-benchmark-server-types
    hypervisor-benchmark-server-config
  ];
  dependencies = {
    cfg-if = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
