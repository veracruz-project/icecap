{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "icecap-host";
  nix.local.dependencies = with localCrates; [
    icecap-host-core
    hypervisor-host-vmm-types
  ];
  dependencies = {
    clap = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
