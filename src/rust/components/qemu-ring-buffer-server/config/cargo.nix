{ mk, localCrates, serdeMin }:

mk {
  name = "icecap-qemu-ring-buffer-server-config";
  localDependencies = with localCrates; [
    icecap-base-config
  ];
  dependencies = {
    serde = serdeMin;
  };
}
