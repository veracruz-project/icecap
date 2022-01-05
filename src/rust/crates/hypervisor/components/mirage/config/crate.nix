{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-mirage-config";
  nix.local.dependencies = with localCrates; [
    icecap-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
