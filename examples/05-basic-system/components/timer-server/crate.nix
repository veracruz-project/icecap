{ crateUtils, icecapSrc, globalCrates, timer-server-types }:

crateUtils.mkCrate {
  nix.name = "timer-server";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-std
    icecap-start-generic
    icecap-driver-interfaces
    icecap-virt-timer-driver
  ]) ++ [
    timer-server-types
  ];
  dependencies = {
    serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
  };
}
