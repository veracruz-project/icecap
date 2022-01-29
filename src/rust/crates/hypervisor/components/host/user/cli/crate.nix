{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "icecap-host";
  nix.local.dependencies = with localCrates; [
    icecap-host-user
    icecap-host-vmm-types
  ];
  dependencies = {
    clap = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
