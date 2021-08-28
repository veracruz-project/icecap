{ runCommandCC, repos, libsel4, libs }:

runCommandCC "object_sizes.yaml" {
  buildInputs = [ libsel4 libs.icecap-autoconf ];
} ''
  $CC -E -P - < ${repos.rel.capdl "object_sizes/object_sizes.yaml"} > $out
''
