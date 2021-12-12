{ mk, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-backtrace-types";
  dependencies = {
    hex = { version = "*"; default-features = false; features = [ "alloc" ]; };
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
