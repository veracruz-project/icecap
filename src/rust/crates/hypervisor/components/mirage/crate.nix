{ mk, localCrates, serdeMin, stdenv }:

mk {
  nix.name = "mirage";
  nix.local.dependencies = with localCrates; [
    finite-set
    icecap-linux-syscall-types
    icecap-linux-syscall-musl
    icecap-std
    icecap-mirage-config
    icecap-event-server-types
    icecap-mirage-core
  ];
  dependencies = {
    serde = serdeMin;
  };
  # nix.buildScript = {
  #   NOTE this doesn't work because of circular dependencies. rustc deduplicates these.
  #   rustc-link-lib = [
  #     "icecap-mirage-glue" "mirage" "sel4asmrun" "c" "gcc"
  #   ];
  # };
  nix.passthru.excludeFromBuild = true;
}
