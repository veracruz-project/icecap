{ mkBin, localCrates }:

mkBin {
  name = "qemu-ring-buffer-server";
  localDependencies = with localCrates; [
    icecap-std
    icecap-qemu-ring-buffer-server-config
  ];
  dependencies = {
    register = "*";
  };
}
