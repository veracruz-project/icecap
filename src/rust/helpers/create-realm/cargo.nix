{ mkBin, localCrates }:

mkBin {
  name = "create-realm";
  localDependencies = with localCrates; [
    icecap-caput-host
  ];
}
