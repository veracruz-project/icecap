{ mkBin, localCrates }:

mkBin {
  name = "icecap-host";
  localDependencies = with localCrates; [
    icecap-host-user
    icecap-host-vmm-types
  ];
  dependencies = {
    clap = "*";
  };
}
