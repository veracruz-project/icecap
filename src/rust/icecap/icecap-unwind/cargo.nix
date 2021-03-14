{ mk }:

mk {
  name = "icecap-unwind";
  dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    log = "*";
  };
}
