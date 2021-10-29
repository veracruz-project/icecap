{ mk, localCrates }:

mk {
  nix.name = "icecap-backtrace-collect";
  nix.local.dependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    log = "*";
    cfg-if = "*";
  };
  nix.local.target."cfg(all(target_os = \"icecap\", icecap_debug))".dependencies = with localCrates; [
    icecap-unwind
  ];
  target."cfg(all(target_os = \"icecap\", icecap_debug))".dependencies = {
    fallible-iterator = { version = "*"; default-features = false; features = [ "alloc" ]; };
    gimli = { version = "0.20.0"; default-features = false; features = [ "read" ]; };
  };
}
