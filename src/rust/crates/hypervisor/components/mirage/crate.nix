{ mkSeL4Bin, localCrates, serdeMin, stdenv }:

mkSeL4Bin {
  nix.name = "hypervisor-mirage";
  nix.local.dependencies = with localCrates; [
    finite-set
    icecap-linux-syscall-types
    icecap-linux-syscall-musl
    icecap-std
    hypervisor-mirage-config
    hypervisor-event-server-types
    icecap-mirage-core
  ];
  dependencies = {
    serde = serdeMin;
  };
  # nix.buildScript = {
  #   NOTE this doesn't work because of circular dependencies. rustc deduplicates these.
  #   rustc-link-lib = [
  #     "hypervisor-mirage-glue" "hypervisor-mirage" "sel4asmrun" "c" "gcc"
  #   ];
  # };
  nix.passthru.excludeFromBuild = true;
}
