{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "icecap-start-generic";
  nix.local.dependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-runtime
    icecap-start
  ];
  dependencies = {
    log = "*"; # TODO
    serde = serdeMin;
    serde_json = { version = "*"; default-features = false; features = [ "alloc" ]; };
    postcard = postcardCommon;
  };
}
