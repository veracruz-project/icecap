{ mkInstance
, icecapSrcAbsSplit
, libs
, trivialSplit
}:

mkInstance (self: with self; {

  minimal = libs.mk {
    name = "minimal";
    root = icecapSrcAbsSplit ./minimal;
    propagatedBuildInputs = with libs; [
      icecap-runtime
    ];
  };

  config = {
    components = {
      minimal.image = trivialSplit "${minimal}/bin/minimal.elf";
    };
  };

  src = ./cdl;

})
