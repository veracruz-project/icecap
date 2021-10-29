{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-config-sys";
  nix.local.dependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  nix.localAttrs.dependencies = {
    icecap-sel4 = {
      features = [
        "use-serde"
      ];
    };
  };
  dependencies = {
    serde = serdeMin;
  };
}
