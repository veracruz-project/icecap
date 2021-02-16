{ mk, localCrates }:

mk {
  name = "icecap-fdt";
  phantomLocalDependencies = with localCrates; [
    icecap-failure
  ];
  dependencies = {
    log = "*";
  };
  target."cfg(target_os = \"icecap\")".dependencies = {
    icecap-failure = { path = "../icecap-failure"; };
  };
  target."cfg(not(target_os = \"icecap\"))".dependencies = {
    failure = { version = "*"; };
  };
}
