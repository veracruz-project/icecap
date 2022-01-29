{ crateUtils, icecapSrc, globalCrates, example-component-config }:

crateUtils.mkCrate {
  nix.name = "example-component";
  nix.isBin = true;
  nix.srcPath = ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-std
  ]) ++ [
    example-component-config
  ];
}
