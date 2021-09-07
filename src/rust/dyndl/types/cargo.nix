{ mk, localCrates, serdeMin }:

mk {
  nix.name = "dyndl-types";
  nix.localDependencies = with localCrates; [
    dyndl-types-derive
  ];
  dependencies = {
    serde = serdeMin;
  };
}
