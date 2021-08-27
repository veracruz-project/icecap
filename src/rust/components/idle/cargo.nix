{ mkBin, localCrates }:

mkBin {
  name = "idle";
  localDependencies = with localCrates; [
    icecap-std
  ];
  dependencies = {
    cortex-a = "=3.0.5";
  };
}
