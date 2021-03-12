{ mk, serdeMin }:

mk {
  name = "icecap-sel4";
  dependencies = {
    serde = serdeMin;
  };
}
