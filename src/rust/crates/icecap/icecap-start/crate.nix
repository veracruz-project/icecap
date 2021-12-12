{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "icecap-start";
  nix.local.dependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-runtime
  ];
  dependencies = {
    log = "*"; # TODO
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
