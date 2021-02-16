{ mkBin, localCrates }:

mkBin {
  name = "vmm";
  localDependencies = with localCrates; [
    icecap-std
    icecap-vmm-config
    icecap-vmm-core
  ];
  dependencies = {
    itertools = { version = "*"; default-features = false; };
  };
}
