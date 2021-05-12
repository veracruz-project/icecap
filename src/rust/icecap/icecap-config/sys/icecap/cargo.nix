{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-config-sys";
  localDependencies = with localCrates; [
    icecap-sel4
    icecap-runtime
  ];
  localDependencyAttributes = {
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
