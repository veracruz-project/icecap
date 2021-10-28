{ mk }:

mk {
  nix.name = "biterate";
  dependencies = {
    num = { version = "*"; default-features = false; };
  };
}
