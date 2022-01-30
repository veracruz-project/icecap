{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-backtrace-collect";
  nix.local.dependencies = with localCrates; [
    icecap-backtrace-types
  ];
  dependencies = {
    cfg-if = "*";
    log = "*";
  };
  nix.local.target."cfg(all(target_os = \"icecap\", icecap_debug))".dependencies = with localCrates; [
    icecap-sel4
  ];
  target."cfg(all(target_os = \"icecap\", icecap_debug))".dependencies = {
    unwinding = { version = "0.1.4"; default-features = false; features = [ "unwinder" "fde-gnu-eh-frame-hdr" ]; };
  };
}
