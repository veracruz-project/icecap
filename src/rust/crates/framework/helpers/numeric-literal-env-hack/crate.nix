{ mkLinux }:

mkLinux {
  nix.name = "numeric-literal-env-hack";
  lib.proc-macro = true;
  dependencies = {
    quote = "0.6.11";
    syn = { version = "0.15.26"; features = [ "full" ]; };
  };
}
