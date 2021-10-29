{ mk, localCrates, patches }:

mk {
  nix.name = "icecap-std";
  nix.local.dependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
    dlmalloc = "=0.1.3";
  };
  nix.propagate = {
    extraManifest = {
      patch.crates-io = {
        dlmalloc.path = patches.dlmalloc.store;
      };
    };
    extraManifestEnv = {
      patch.crates-io = {
        dlmalloc.path = patches.dlmalloc.env;
      };
    };
  };
}
