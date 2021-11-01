{ runCommandCC, seL4EcosystemRepos, libsel4 }:

runCommandCC "object_sizes.yaml" {
  buildInputs = [ libsel4 ];
} ''
  $CC -E -P - < ${seL4EcosystemRepos.capdl.extendInnerSuffix "object_sizes/object_sizes.yaml"} > $out
''
