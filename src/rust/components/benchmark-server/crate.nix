{ mkBin, localCrates, lib, benchmark }:

mkBin {
  nix.name = "benchmark-server";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-std
    icecap-plat
    icecap-rpc-sel4
    icecap-benchmark-server-types
    icecap-benchmark-server-config
  ];
  features = {
    default = lib.optional benchmark "benchmark";
    benchmark = [ "icecap-sel4/benchmark" ];
  };
}
