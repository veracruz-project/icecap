{ runCommandCC, seL4EcosystemRepos, libsel4, libs }:

runCommandCC "object_sizes.yaml" {
  buildInputs = [ libsel4 libs.icecap-autoconf ];
} ''
  $CC -E -P - < ${seL4EcosystemRepos.capdl.extendInnerSuffix "object_sizes/object_sizes.yaml"} > $out
''
