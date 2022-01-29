{ mk, localCrates, serdeMin }:

mk {
  nix.name = "hypervisor-fdt-bindings";
  nix.local.dependencies = with localCrates; [
    icecap-fdt
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
  nix.passthru.excludeFromDocs = true;
}
