{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-caput-config";
  localDependencies = with localCrates; [
    icecap-config-common
    icecap-qemu-ring-buffer-server-config
    dyndl-types
  ];
  dependencies = {
    serde = serdeMin;
  };
}
