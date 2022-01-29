{ mkLinuxBin, localCrates }:

mkLinuxBin {
  nix.name = "hypervisor-fdt-append-devices";
  nix.local.dependencies = with localCrates; [
    icecap-fdt
    hypervisor-fdt-bindings
  ];
  dependencies = {
    serde = "*";
    serde_json = "*";
  };
  nix.passthru.excludeFromDocs = true;
}
