{ mkBin, localCrates }:

mkBin {
  name = "append-icecap-devices";
  localDependencies = with localCrates; [
    icecap-fdt
    icecap-fdt-bindings
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}
