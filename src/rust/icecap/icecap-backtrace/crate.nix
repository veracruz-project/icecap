{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-backtrace";
  nix.local.dependencies = with localCrates; [
    icecap-runtime
    icecap-backtrace-types
    icecap-backtrace-collect
  ];
}
