{ lib, runCommand, cpio }:

links:

runCommand "archive.cpio" {
  nativeBuildInputs = [ cpio ];
} ''
  cp -rL ${links} links
  ls links | cpio -o -D links -L --reproducible -H newc --file=$out
''
  # TODO ^hack to handle case where multiple links have the same target
  # ls ${links} | cpio -o -D ${links} -L --reproducible -H newc --file=$out
