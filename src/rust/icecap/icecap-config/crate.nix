{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-config";
  nix.localDependencies = with localCrates; [
    icecap-config-sys
  ];
  dependencies = {
    serde = serdeMin;
  };
}
