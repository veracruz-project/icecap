{ crateUtils, icecapSrc }:

crateUtils.mkGeneric {
  name = "rust-helper";
  isBin = true;
  src = icecapSrc.absoluteSplit ./src;
}
