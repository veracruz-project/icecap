{ lib, writeText, runCommand, runCommandCC, cpio }:

{

  mk = files:

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
      '';
        # TODO ^hack to handle case where multiple links have the same target
        # cpio -o -D ${links} -L --reproducible -H newc --file=$out < ${paths}

  mkFrom = links:

    runCommand "archive.cpio" {
      nativeBuildInputs = [ cpio ];
    } ''
      cp -rL ${links} links
      ls links | cpio -o -D links -L --reproducible -H newc --file=$out
    '';
      # TODO ^hack to handle case where multiple links have the same target
      # ls ${links} | cpio -o -D ${links} -L --reproducible -H newc --file=$out

  mkObj =

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
    '';

}
