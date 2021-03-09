{ mkInstance
, compose, stripElfSplit
, icecapSrcAbsSplit
, libs
}:

mkInstance (self: with self; {

  composition = compose {
    src = ./cdl;
    config = {
      components = {
        minimal.image = stripElfSplit "${minimal}/bin/minimal.elf";
      };
    };
  };

  minimal = libs.mk {
    name = "minimal";
    root = icecapSrcAbsSplit ./minimal;
    propagatedBuildInputs = with libs; [
      icecap-runtime
    ];
  };

})
