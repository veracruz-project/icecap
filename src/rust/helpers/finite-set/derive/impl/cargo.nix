{ mk, localCrates }:

mk {
  name = "finite-set-derive-impl";
  dependencies = {
    proc-macro2 = "1";
    quote = "1";
    syn = "1.0.3";
    synstructure = "0.12.0";
  };
}
