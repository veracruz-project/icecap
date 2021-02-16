{ mk, localCrates, serdeMin }:

mk {
  name = "dyndl-realize";
  localDependencies = with localCrates; [
    dyndl-types
    icecap-core
  ];
  dependencies = {
    serde = serdeMin;
    log = "*";
  };
}
