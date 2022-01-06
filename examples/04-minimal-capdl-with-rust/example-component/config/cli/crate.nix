{ crateUtils, icecapSrc, globalCrates, example-component-config }:

crateUtils.mkCrate {
  nix.name = "serialize-example-component-config";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-config-cli-core
  ]) ++ [
    example-component-config
  ];
}
