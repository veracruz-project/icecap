{ mk, serdeMin }:

mk {
  name = "icecap-runtime-config";
  dependencies = {
    serde = serdeMin;
  };
}
