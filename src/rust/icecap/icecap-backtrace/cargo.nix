{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace";
  nix.localDependencies = with localCrates; [
    icecap-backtrace-types
    icecap-backtrace-collect
  ];
  dependencies = {
    # fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    # gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    # log = "*";
  };
}
