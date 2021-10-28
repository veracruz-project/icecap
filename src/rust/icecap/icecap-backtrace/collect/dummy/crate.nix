{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace-collect";
  nix.localDependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    log = "*";
  };
}
