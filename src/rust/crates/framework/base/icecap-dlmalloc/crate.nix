{ mkSeL4, localCrates }:

mkSeL4 {
  nix.name = "icecap-dlmalloc";
  nix.local.dependencies = with localCrates; [
    icecap-sync
  ];
  dependencies = {
    dlmalloc = "0.2.3";
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
      "dlmalloc/rustc-dep-of-std"
      "icecap-sync/rustc-dep-of-std"
    ];
  };
}
