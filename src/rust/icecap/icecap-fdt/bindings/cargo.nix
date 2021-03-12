{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-fdt-bindings";
  localDependencies = with localCrates; [
    icecap-fdt
    icecap-failure
    icecap-failure_dummy
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
}
