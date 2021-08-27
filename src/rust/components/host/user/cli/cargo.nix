{ mkBin, localCrates }:

mkBin {
  name = "icecap-host";
  localDependencies = with localCrates; [
    icecap-host-user
  ];
  dependencies = {
    clap = "*"; bitflags = "=1.2";
  };
}
