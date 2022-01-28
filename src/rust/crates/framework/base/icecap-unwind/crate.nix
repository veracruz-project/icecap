{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-unwind";
  nix.local.target."cfg(target_os = \"icecap\")".dependencies = with localCrates; [
    icecap-runtime
  ];
  dependencies = {
    log = "*";
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
}
