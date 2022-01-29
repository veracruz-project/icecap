{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "icecap-append-devices";
  nix.local.dependencies = with localCrates; [
    icecap-fdt
    icecap-fdt-bindings
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
