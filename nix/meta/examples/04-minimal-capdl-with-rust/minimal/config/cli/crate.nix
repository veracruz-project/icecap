{ crateUtils, icecapSrc, globalCrates, minimal-config }:

crateUtils.mkCrate {
  nix.name = "serialize-minimal-config";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-config-cli-core
  ]) ++ [
    minimal-config
  ];
}
