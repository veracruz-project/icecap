{ mkSeL4 }:

mkSeL4 {
  nix.name = "icecap-logger";
  dependencies = {
    log = "*";
  };
}
