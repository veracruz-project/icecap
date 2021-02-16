{ mk, localCrates, serdeMin }:

mk {
  name = "dyndl-types";
  localDependencies = with localCrates; [
    dyndl-types-derive
  ];
  dependencies = {
    serde = serdeMin;
  };
}
