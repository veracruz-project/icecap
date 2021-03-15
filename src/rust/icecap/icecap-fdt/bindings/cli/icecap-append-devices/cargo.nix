{ mkBin, localCrates }:

mkBin {
  name = "icecap-append-devices";
  localDependencies = with localCrates; [
    icecap-fdt
    icecap-fdt-bindings
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}
