{ mk, localCrates, numCores }:

mk {
  nix.name = "icecap-plat";
  nix.buildScript = {
    rustc-env.NUM_CORES = toString numCores;
  };
  nix.localDependencies = with localCrates; [
    numeric-literal-env-hack
  ];
  dependencies = {
    cfg-if = "*";
  };
}
