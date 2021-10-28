{ mk, localCrates, serdeMin }:

mk {
  nix.name = "icecap-config-sys";
  nix.localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  nix.localDependencyAttributes = {
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
