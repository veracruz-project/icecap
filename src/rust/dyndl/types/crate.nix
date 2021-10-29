{ mk, localCrates, serdeMin }:

mk {
  nix.name = "dyndl-types";
  nix.local.dependencies = with localCrates; [
    dyndl-types-derive
  ];
  dependencies = {
    serde = serdeMin;
  };
}
