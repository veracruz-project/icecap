{ mk, serdeMin }:

mk {
  name = "icecap-config-sys";
  dependencies = {
    serde = serdeMin;
  };
}
