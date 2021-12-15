{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-config";
  nix.local.dependencies = with localCrates; [
    icecap-config-sys
  ];
  dependencies = {
    serde = serdeMin;
  };
}
