{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-fdt-bindings";
  localDependencies = with localCrates; [
    icecap-fdt
  ];
  phantomLocalDependencies = with localCrates;[
    icecap-failure
  ];
  dependencies = {
    log = "*";
    serde = serdeMin;
  };
  target."cfg(target_os = \"icecap\")".dependencies = {
    icecap-failure = { path = "../icecap-failure"; };
  };
  target."cfg(not(target_os = \"icecap\"))".dependencies = {
    failure = { version = "*"; };
  };
}
