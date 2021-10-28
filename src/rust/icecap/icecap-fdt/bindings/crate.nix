{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-fdt-bindings";
  nix.localDependencies = with localCrates; [
    icecap-fdt
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
}
