{ crateUtils, icecapSrcAbsSplit }:

crateUtils.mkGeneric {
  name = "rust-helper";
  isBin = true;
  src = icecapSrcAbsSplit ./src;
}
