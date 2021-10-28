{ mk, localCrates, serdeMin, lib, benchmark }:

mk {
  nix.name = "icecap-sel4";
  nix.localDependencies = with localCrates; [
    icecap-sel4-derive
    icecap-sel4-sys
  ];
  dependencies = {
    serde = serdeMin // {
      optional = true;
    };
    core = {
      optional = true;
      package = "rustc-std-workspace-core";
      version = "1.0.0";
    };
    alloc = {
      optional = true;
      package = "rustc-std-workspace-alloc";
      version = "1.0.0";
    };
    compiler_builtins = {
      optional = true;
      version = "0.1.0";
    };
  };
  features = {
    default = lib.optional benchmark "benchmark";
    benchmark = [];
    use-serde = [
      "serde"
    ];
    rustc-dep-of-std = [
      "core"
      "alloc"
      "compiler_builtins/rustc-dep-of-std"
      "icecap-sel4-sys/rustc-dep-of-std"
    ];
  };
}
