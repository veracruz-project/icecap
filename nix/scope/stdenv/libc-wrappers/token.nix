{ runCommandCC }:

runCommandCC "libc" {} ''
  mkdir -p $out/lib

  touch empty.s
  $AS empty.s -o empty.o

  cp empty.o $out/lib/crt0.o
  cp empty.o $out/lib/crt1.o
  cp empty.o $out/lib/crti.o
  cp empty.o $out/lib/crtn.o

  $AR r $out/lib/libc.a empty.o
  $AR r $out/lib/libm.a empty.o
''
