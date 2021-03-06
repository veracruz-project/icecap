{ mkLinuxBin, localCrates, postcardCommon }:

mkLinuxBin {
  nix.name = "dyndl-serialize-spec";
  nix.local.dependencies = with localCrates; [
    dyndl-types
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
    postcard = postcardCommon;
    sha2 = "*";
  };
}
