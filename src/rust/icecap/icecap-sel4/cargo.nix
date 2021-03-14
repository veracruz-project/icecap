{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-sel4";
  localDependencies = with localCrates; [
    icecap-sel4-derive
    icecap-sel4-sys
  ];
  dependencies = {
    serde = serdeMin;
  };
}
