# Just for cross-compiling OCaml libraries

{ runCommandCC
, muslc
, writeText
}:

let
  hack = writeText "hack.c" ''
    int sigsetjmp(void) {
        return 0;
    }
  '';
in

runCommandCC "libc" {} ''
  mkdir -p $out/lib
  ln -s ${muslc}/include $out
  cp --no-preserve=mode ${muslc}/lib/lib{c,m,g}.a $out/lib

  $CC -c ${hack} -o hack.o
  $AR r $out/lib/libc.a hack.o

  touch empty.s
  $AS empty.s -o empty.o

  cp empty.o $out/lib/crt0.o
  cp empty.o $out/lib/crti.o
  cp empty.o $out/lib/crtn.o

  $AR r $out/lib/libpthread.a empty.o
''
