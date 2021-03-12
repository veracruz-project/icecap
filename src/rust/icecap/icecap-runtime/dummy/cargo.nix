{ mk, serdeMin }:

mk {
  name = "icecap-runtime";
  dependencies = {
    serde = serdeMin;
  };
}
