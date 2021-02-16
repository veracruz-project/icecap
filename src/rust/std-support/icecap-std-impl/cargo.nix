{ mk }:

mk {
  name = "icecap-std-impl";
  dependencies = {
    core = {
      optional = true;
      package = "rustc-std-workspace-core";
      version = "1.0.0";
    };
    compiler_builtins = { version = "0.1.0"; optional = true; };
    # alloc = {
    #   optional = true;
    #   package = "rustc-std-workspace-alloc";
    #   version = "1.0.0";
    # };
  };
  features = {
    rustc-dep-of-std = [
      "core"
      "compiler_builtins/rustc-dep-of-std"
      # "alloc"
    ];
  };
}
