{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace-collect";
  nix.local.dependencies = with localCrates; [
    icecap-unwind
    icecap-backtrace-types
  ];
  dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    log = "*";
  };
}
