{ mkLinux }:

mkLinux {
  nix.name = "finite-set-derive";
  lib.proc-macro = true;
  dependencies = {
    proc-macro2 = "1";
    quote = "1";
    syn = "1.0.3";
    synstructure = "0.12.0";
  };
}
