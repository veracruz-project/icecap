{ mk, localCrates }:

mk {
  nix.name = "icecap-std-impl";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
    icecap-sync
  ];
  dependencies = {
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
    rustc-dep-of-std = [
      "core"
      "alloc"
      "compiler_builtins/rustc-dep-of-std"
      "icecap-sel4/rustc-dep-of-std"
      "icecap-runtime/rustc-dep-of-std"
      "icecap-sync/rustc-dep-of-std"
    ];
  };
}
