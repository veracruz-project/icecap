{ mk, localCrates, serdeMin }:

mk {
  nix.name = "dyndl-realize-simple-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
