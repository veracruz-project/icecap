{ mkIceCapSrc }:

let
  mkPatch = pre: { suffix ? "" }: rev:
    mkIceCapSrc {
      repo = pre;
      inherit rev;
      inherit suffix;
    };

in {

  dlmalloc = mkPatch "minor-patches/rust/dlmalloc" {} "f6759cfed44dc4135eaa43c8c26599357749af39";

}
