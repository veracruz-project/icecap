{ runCommandCC, icecapExternalSrc, libsel4 }:

runCommandCC "object_sizes.yaml" {
  buildInputs = [ libsel4 ];
} ''
  $CC -E -P - < ${icecapExternalSrc.capdl.extendInnerSuffix "object_sizes/object_sizes.yaml"} > $out
''
