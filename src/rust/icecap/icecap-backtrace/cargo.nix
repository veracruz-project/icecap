{ mk, localCrates }:

mk {
  name = "icecap-backtrace";
  localDependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    log = "*";
  };
}