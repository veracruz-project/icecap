{ runCommandCC, repos, libsel4, libs }:

# TODO is this sound?
runCommandCC "object_sizes.yaml" {
  buildInputs = [ libsel4 libs.icecap-autoconf ];
} ''
  grep -v autoconf.h ${repos.rel.capdl "object_sizes/object_sizes.yaml"} | $CC -E -P - > $out
''
