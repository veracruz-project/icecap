{ lib, writeText, runCommandCC
}:

{ files
, symbolPrefix ? "_file_"
, libName ? "files"
}:

with lib;

let
  files_s = writeText "${libName}.s" ''
    .section ._files,"aw"
    ${concatStrings (mapAttrsToList (k: v:
      let
        symbolName = "${symbolPrefix}${k}";
      in ''
        .globl ${symbolName}, ${symbolName}_end
        ${symbolName}:
        .incbin "${v}"
        ${symbolName}_end:
      ''
    ) files)}
  '';

  files_obj = runCommandCC "${libName}.o" {} ''
    $CC -c ${files_s} -o $out
  '';

in
runCommandCC libName {
  passthru = {
    graph.${libName} = [];
    inherit files_obj;
  };
} ''
  mkdir -p $out/lib
  cp ${files_obj} ${files_obj.name}
  $AR r $out/lib/lib${libName}.a ${files_obj.name}
''
