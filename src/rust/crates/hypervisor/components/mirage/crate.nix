{ mkExcludeBin, localCrates, serdeMin, stdenv }:

mkExcludeBin {
  nix.name = "mirage";
  nix.local.dependencies = with localCrates; [
    icecap-linux-syscall
    icecap-std
    icecap-start-generic
    icecap-event-server-types
  ];
  dependencies = {
    serde = serdeMin;
    serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
  };
  # nix.buildScript = {
  #   NOTE this doesn't work because of circular dependencies. rustc deduplicates these.
  #   rustc-link-lib = [
  #     "icecap-mirage-glue" "mirage" "sel4asmrun" "c" "gcc"
  #   ];
  # };
}
