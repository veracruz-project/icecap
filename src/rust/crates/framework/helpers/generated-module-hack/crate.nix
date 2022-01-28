{ mk }:

mk {
  nix.name = "generated-module-hack";
  lib.proc-macro = true;
  dependencies = {
    quote = "0.6.11";
    syn = { version = "0.15.26"; };
  };
}
