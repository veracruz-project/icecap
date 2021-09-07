{ runCommandCC
, writeText
}:

let
  empty-c = writeText "empty.c" ''
  '';

  empty-o = runCommandCC "empty.o" {} ''
    $CC ${empty-c} -c -o $out
  '';

  empty-a = runCommandCC "empty.a" {} ''
    $AR r $out ${empty-o}
  '';

in
runCommandCC "libc" {} ''
  mkdir -p $out/lib
  ln -s ${empty-a} $out/lib/libc.a
  ln -s ${empty-a} $out/lib/libg.a
''

# TODO
#   ln -s ${libs.icecap-runtime}/lib/crt0.o $out/lib
# '' + lib.optionalString (hostPlatform.system == "aarch64-linux") ''
#   mv $out/lib/crt0.o $out/lib/crt1.o
# ''
