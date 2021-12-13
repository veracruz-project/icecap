{ mk, serdeMin, postcardCommon }:

mk {
  nix.name = "icecap-backtrace-types";
  dependencies = {
    hex = { version = "0.4.3"; default-features = false; features = [ "alloc" ]; };
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
