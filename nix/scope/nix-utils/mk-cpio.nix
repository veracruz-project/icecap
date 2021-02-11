{ lib, writeText, runCommand, cpio }:

files:

let
  links = runCommand "links" {} ''
    ${lib.concatMapStrings ({ path, contents }: ''
      mkdir -p $out/$(dirname ${path})
      ln -s ${contents} $out/${path}
    '') files}
  '';

  paths = writeText "paths.txt" ''
    ${lib.concatMapStrings ({ path, contents }: ''
      ${path}
    '') files}
  '';

in
runCommand "archive.cpio" {
  nativeBuildInputs = [ cpio ];
} ''
  cp -rL ${links} links
  cpio -o -D links -L --reproducible -H newc --file=$out < ${paths}
''
  # TODO ^hack to handle case where multiple links have the same target
  # cpio -o -D ${links} -L --reproducible -H newc --file=$out < ${paths}
