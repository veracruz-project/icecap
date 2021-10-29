{ lib, mk, localCrates }:

mk {
  nix.name = "icecap-unwind";
  nix.local.target."cfg(target_os = \"icecap\")".dependencies = with localCrates; [
    icecap-runtime
  ];
  dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    log = "*";
  };
}
