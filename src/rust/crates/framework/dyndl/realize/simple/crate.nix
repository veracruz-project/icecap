{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "dyndl-realize-simple";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    dyndl-realize
    dyndl-realize-simple-config
    icecap-core
  ];
}
