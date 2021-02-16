{ mk, localCrates, patches }:

mk {
  name = "icecap-std";
  localDependencies = with localCrates; [
    icecap-core
  ];
  dependencies = {
    log = "*";
    dlmalloc = { version = "=0.1.3"; };
  };
  propagate = {
    extraManifest = {
      patch.crates-io = {
        dlmalloc.path = patches.dlmalloc.store;
      };
    };
    extraManifestLocal = {
      patch.crates-io = {
        dlmalloc.path = patches.dlmalloc.env;
      };
    };
  };
}
