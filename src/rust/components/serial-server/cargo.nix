{ mkBin, localCrates }:

mkBin {
  name = "serial-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-serial-server-config
  ];
  dependencies = {
    register = "*";
  };
}
