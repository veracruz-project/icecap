{ mkBin, localCrates }:

mkBin {
  name = "icecap-host-cli";
  localDependencies = with localCrates; [
    icecap-caput-host
  ];
}
