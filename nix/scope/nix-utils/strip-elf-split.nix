{ stripElf }:

elf: {
  full = elf;
  min = stripElf elf;
}
