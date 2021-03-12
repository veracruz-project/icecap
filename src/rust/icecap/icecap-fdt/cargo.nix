{ mk, localCrates }:

mk {
  name = "icecap-fdt";
  localDependencies = with localCrates; [
    icecap-failure
  ];
  dependencies = {
    log = "*";
  };
}
