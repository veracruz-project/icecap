{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-runtime";
  localDependencies = with localCrates; [
    icecap-sel4
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
