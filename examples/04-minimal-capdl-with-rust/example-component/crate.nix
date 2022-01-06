{ crateUtils, icecapSrc, globalCrates, example-component-config }:

crateUtils.mkCrate {
  nix.name = "example-component";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-std
  ]) ++ [
    example-component-config
  ];
}
