{ runCommandCC }:

elf: runCommandCC "stripped.elf" {} ''
  $STRIP -s ${elf} -o $out
''
