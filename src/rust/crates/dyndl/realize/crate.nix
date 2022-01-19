{ mkSeL4, localCrates, serdeMin, postcardCommon }:

mkSeL4 {
  nix.name = "dyndl-realize";
  nix.local.dependencies = with localCrates; [
    dyndl-types
    icecap-core
  ];
  dependencies = {
    log = "*";
    sha2 = { version = "*"; default-features = false; };
  };
}
