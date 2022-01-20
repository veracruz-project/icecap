{ crateUtils, icecapSrc, globalCrates }:

crateUtils.mkCrate {
  nix.name = "root-task";
  nix.isBin = true;
  nix.srcPath = icecapSrc.absolute ./src;
  nix.local.dependencies = with globalCrates; [
    icecap-std
    icecap-fdt
  ];
}
