{ mkBin, localCrates }:

mkBin {
  name = "icecap-host";
  localDependencies = with localCrates; [
    icecap-host-core
  ];
  dependencies = {
    clap = "*";
  };
}
