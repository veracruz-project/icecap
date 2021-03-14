{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-fdt-bindings";
  localDependencies = with localCrates; [
    icecap-fdt
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
}
