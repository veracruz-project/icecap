{ mkBin, localCrates }:

mkBin {
  nix.name = "fault-handler";
  nix.local.dependencies = with localCrates; [
    icecap-std
    icecap-fault-handler-config
  ];
}
