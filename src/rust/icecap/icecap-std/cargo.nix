{ mk, localCrates, patches }:

mk {
  nix.name = "icecap-std";
  nix.localDependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
    dlmalloc = { version = "=0.1.3"; };
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
