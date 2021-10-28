{ mkBin, localCrates }:

mkBin {
  nix.name = "icecap-append-devices";
  nix.localDependencies = with localCrates; [
    icecap-fdt
    icecap-fdt-bindings
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
}
