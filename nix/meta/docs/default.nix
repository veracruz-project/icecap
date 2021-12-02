{ lib, pkgs, meta }:

{
  all = pkgs.dev.runCommand "docs" {} ''
    rustdoc_root=$out/rustdoc
    mkdir -p $rustdoc_root
    ${lib.concatMapStrings (adHoc: ''
      x=$rustdoc_root/${adHoc.adHocPath}
      mkdir -p $(dirname $x)
      cp -r ${adHoc}/doc $x
    '') meta.adHocBuildTests.allList}
  '';
}
