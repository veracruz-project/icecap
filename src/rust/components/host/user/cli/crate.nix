{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-host";
  nix.localDependencies = with localCrates; [
    icecap-host-user
    icecap-host-vmm-types
  ];
  dependencies = {
    clap = "*";
  };
}
