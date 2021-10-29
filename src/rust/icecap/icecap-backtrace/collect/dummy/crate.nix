{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace-collect";
  nix.local.dependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    log = "*";
  };
}
