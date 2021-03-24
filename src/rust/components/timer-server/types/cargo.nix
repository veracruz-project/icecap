{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-timer-server-types";
  localDependencies = with localCrates; [
    icecap-rpc
  ];
  dependencies = {
  };
}
