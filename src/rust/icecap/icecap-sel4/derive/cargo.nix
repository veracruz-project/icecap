{ mk }:

mk {
  nix.name = "icecap-sel4-derive";
  lib.proc-macro = true;
  dependencies = {
    quote = "*";
    syn = "*";
  };
}
