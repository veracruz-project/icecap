{ mk, callPackage }:

# HACK
with callPackage ({ icecapPlat, platUtils, writeText } @ args: args) {};

mk {
  nix.name = "icecap-plat";
  nix.buildScript = {
    # HACK use a file to get around the fact that rust's 'env!()' can only be used for string constants
    rustc-env.NUM_CORES = writeText "num_cores.rs" ''
      ${toString platUtils.${icecapPlat}.numCores}
    '';
  };
  dependencies = {
    cfg-if = "*";
  };
}
