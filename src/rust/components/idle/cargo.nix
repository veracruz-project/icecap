{ mkBin, localCrates }:

mkBin {
  nix.name = "idle";
  nix.localDependencies = with localCrates; [
    icecap-std
  ];
  dependencies = {
    cortex-a = "*";
  };
}
