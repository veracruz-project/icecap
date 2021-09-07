{ mk, icecap-sel4-sys-gen }:

mk {
  nix.name = "icecap-sel4-sys";
  nix.buildScript = {
    rustc-env.GEN_RS = icecap-sel4-sys-gen;
    rustc-link-lib = [
      "outline" "sel4"
      "icecap_runtime" "icecap_utils" "icecap_pure" # TODO this should be elsewhere
    ];
  };
  dependencies = {
    core = {
      optional = true;
      package = "rustc-std-workspace-core";
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
      "compiler_builtins/rustc-dep-of-std"
    ];
  };
}
