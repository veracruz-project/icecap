{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace";
  nix.localDependencies = with localCrates; [
    icecap-runtime
    icecap-backtrace-types
    icecap-backtrace-collect
  ];
}
