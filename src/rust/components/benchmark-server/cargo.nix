{ mkBin, localCrates, lib, benchmark }:

mkBin {
  nix.name = "benchmark-server";
  nix.localDependencies = with localCrates; [
    icecap-sel4
    icecap-std
    icecap-rpc-sel4
    icecap-benchmark-server-types
    icecap-benchmark-server-config
  ];
  features = {
    default = lib.optional benchmark "benchmark";
    benchmark = [ "icecap-sel4/benchmark" ];
  };
}
