{ mkInstance
, icecapSrcAbsSplit
, libs
}:

mkInstance (self: with self; {

  minimal = libs.mkRoot {
    name = "minimal";
    root = icecapSrcAbsSplit ./minimal;
    propagatedBuildInputs = with libs; [
      icecap-runtime-root
      icecap-utils
    ];
  };

  payload = "${minimal}/bin/minimal.elf";

})
