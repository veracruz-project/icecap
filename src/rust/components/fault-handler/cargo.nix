{ mkBin, localCrates }:

mkBin {
  name = "fault-handler";
  localDependencies = with localCrates; [
    icecap-std
    icecap-fault-handler-config
  ];
}
