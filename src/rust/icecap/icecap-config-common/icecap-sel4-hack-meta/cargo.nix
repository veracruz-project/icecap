{ mk, serdeMin }:

mk {
  name = "icecap-sel4-hack-meta";
  dependencies = {
    serde = serdeMin;
  };
}
