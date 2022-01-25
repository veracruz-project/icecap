{ lib, writeText, runCommand, runCommandCC, linkFarm, cpio
, icecapSrc
}:

# NOTE
# GNU cpio with `-L -H newc` displays the following errant behavior:
#   - incorrect ordering of files in the archive
#   - incorrect handling of cases multiple links have the same target
# As a workaround, we replace `-L` with a temporary directory and `cp -rL`.

{

  # for when order matters
  mk = files:
    let
      links = linkFarm "links" files;
      txt = lib.concatMapStrings ({ name, ... }: "${name}\n") files;
    in runCommand "archive.cpio" {
      nativeBuildInputs = [ cpio ];
    } ''
      cp -rL ${links} links # HACK see above
      printf %s $'${txt}' | cpio -o -D links --reproducible -H newc > $out
    '';

  mkFrom = links: runCommand "archive.cpio" {
    nativeBuildInputs = [ cpio ];
  } ''
    cp -rL ${links} links # HACK see above
    (cd links && find . -not -type d | cpio -o --reproducible -H newc > $out)
  '';

  mkObj = { archive-cpio, symbolName }: runCommandCC "embedded-file.o" {} ''
    $CC -c -x assembler-with-cpp ${icecapSrc.relative "c/support/embedded-file.S"} -o $out \
      -DSYMBOL=${symbolName} -DFILE=${archive-cpio} -DSECTION=_archive_cpio
  '';

}
