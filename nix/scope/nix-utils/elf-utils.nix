{ runCommandCC }:

rec {

  strip = elf: runCommandCC "stripped.elf" {} ''
    $STRIP -s ${elf} -o $out
  '';

  split = elf: {
    full = elf;
    min = strip elf;
  };

  splitTrivially = elf: {
    full = elf;
    min = elf;
  };

}
