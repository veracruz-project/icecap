{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-config-sys";
  nix.local.target."cfg(target_os = \"icecap\")".dependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  nix.localAttrs.target."cfg(target_os = \"icecap\")".dependencies = {
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
