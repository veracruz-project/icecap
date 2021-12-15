{ mk }:

mk {
  nix.name = "icecap-fdt";
  dependencies = {
    log = "*";
  };
}
