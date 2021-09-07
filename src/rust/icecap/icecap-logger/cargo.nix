{ mk }:

mk {
  nix.name = "icecap-logger";
  dependencies = {
    log = "*";
  };
}
