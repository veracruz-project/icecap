{ icecapSrc }:

let
  mkPatch = pre: { suffix ? "" }: rev:
    icecapSrc.repo {
      repo = pre;
      inherit rev;
      innerSuffix = suffix;
    };

in {

  dlmalloc = mkPatch "minor-patches/rust/dlmalloc" {} "f6759cfed44dc4135eaa43c8c26599357749af39";

}
