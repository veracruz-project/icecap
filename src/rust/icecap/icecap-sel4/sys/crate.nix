{ mk, localCrates }:

mk {
  nix.name = "icecap-sel4-sys";
  nix.buildScriptHack = true;
  nix.keepFilesHack = [
    "wrapper.h"
  ];
  nix.local.target."cfg(not(target_os = \"icecap\"))".dependencies = with localCrates; [
    absurdity
  ];
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
  build-dependencies = {
    bindgen = "*";
  };
  features = {
    rustc-dep-of-std = [
      "core"
      "compiler_builtins/rustc-dep-of-std"
    ];
  };
}
