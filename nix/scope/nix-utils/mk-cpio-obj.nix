{ lib, writeText, runCommandCC }:

{ archive-cpio
, symbolName ? "_cpio_archive"
, libName ? "archive"
}:

let
  archive-s = writeText "${libName}.s" ''
    .section ._archive_cpio,"aw"
    .globl ${symbolName}, ${symbolName}_end
    ${symbolName}:
    .incbin "${archive-cpio}"
    ${symbolName}_end:
  '';

  archive-obj = runCommandCC "${libName}.o" {} ''
    $CC -c ${archive-s} -o $out
  '';

in
runCommandCC libName {
  passthru = {
    providesLibs = [ libName ];
    inherit archive-cpio archive-obj;
  };
} ''
  mkdir -p $out/lib
  cp ${archive-obj} ${archive-obj.name}
  $AR r $out/lib/lib${libName}.a ${archive-obj.name}
''
