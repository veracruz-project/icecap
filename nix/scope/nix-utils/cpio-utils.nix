{ lib, writeText, runCommand, runCommandCC, linkFarm, cpio
, icecapSrc
}:

{

  # for when order matters
  mk = files:
    let
      links = linkFarm "links" files;
      txt = lib.concatMapStrings ({ name, ... }: "${name}\n") files;
    in runCommand "archive.cpio" {
      nativeBuildInputs = [ cpio ];
    } ''
      cp -rL ${links} links # HACK to handle case where multiple links have the same target
      printf %s $'${txt}' | cpio -o -D links -L --reproducible -H newc > $out
    '';

  mkFrom = links: runCommand "archive.cpio" {
    nativeBuildInputs = [ cpio ];
  } ''
    cp -rL ${links} links # HACK to handle case where multiple links have the same target
    (cd links && find . -not -type d | cpio -o -L --reproducible -H newc > $out)
  '';

  mkObj = { archive-cpio, symbolName }: runCommandCC "embedded-file.o" {} ''
    $CC -c -x assembler-with-cpp ${icecapSrc.relative "c/support/embedded-file.S"} -o $out \
      -DSYMBOL=${symbolName} -DFILE=${archive-cpio} -DSECTION=_archive_cpio
  '';

}
