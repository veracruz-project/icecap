{ mkBin, localCrates }:

mkBin {
  nix.name = "fault-handler";
  nix.localDependencies = with localCrates; [
    icecap-std
    icecap-fault-handler-config
  ];
}
