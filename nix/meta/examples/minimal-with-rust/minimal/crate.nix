{ crateUtils, icecapSrc, globalCrates, minimal-config }:

crateUtils.mkCrate {
  nix.name = "minimal";
  nix.isBin = true;
  nix.src = icecapSrc.absoluteSplit ./src;
  nix.local.dependencies = (with globalCrates; [
    icecap-std
  ]) ++ [
    minimal-config
  ];
}
