{ lib, mk, localCrates, seL4 }:

mk {
  nix.name = "icecap-unwind";
  nix.local.dependencies = with localCrates; lib.optionals seL4 [
    icecap-runtime
  ];
  dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    log = "*";
  };
}
