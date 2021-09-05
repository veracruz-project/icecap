{ mk }:

mk {
  name = "crosvm-9p-wire-format-derive";
  lib.proc-macro = true;
  dependencies = {
    proc-macro2 = "1.0.8";
    quote = "1.0.2";
    syn = "1.0.14";
  };
}
