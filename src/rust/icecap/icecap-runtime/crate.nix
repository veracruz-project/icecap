{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-runtime";
  nix.localDependencies = with localCrates; [
    icecap-sel4
  ];
  nix.buildScript = {
    rustc-link-lib = [ "icecap_runtime" "icecap_utils" ];
  };
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
    use-serde = [
      "serde"
      "icecap-sel4/use-serde"
    ];
    rustc-dep-of-std = [
      "core"
      "alloc"
      "compiler_builtins/rustc-dep-of-std"
      "icecap-sel4/rustc-dep-of-std"
    ];
  };
}
