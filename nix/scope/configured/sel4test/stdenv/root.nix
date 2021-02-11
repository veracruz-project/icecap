{ runCommandCC
, libsel4runtime
, lib, hostPlatform
}:

runCommandCC "libc" {} (''
  mkdir -p $out/lib
  cp ${libsel4runtime}/lib/crt{i,n}.o $out/lib
  cp ${libsel4runtime}/lib/sel4_crt0.o $out/lib/crt0.o
'' + lib.optionalString (hostPlatform.system == "aarch64-linux") ''
  mv $out/lib/crt0.o $out/lib/crt1.o
'')
