{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "icecap-start";
  nix.local.dependencies = with localCrates; [
    icecap-failure
    icecap-sel4
    icecap-runtime
  ];
  dependencies = {
    serde = serdeMin;
    postcard = postcardCommon;
  };
}
