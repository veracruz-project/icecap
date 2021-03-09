{ mkInstance
, compose, stripElfSplit
, icecapSrcAbsSplit
, libs
}:

mkInstance (self: with self; {

  allDebugFiles = false;

  composition = compose {
    app-elf = stripElfSplit "${minimal}/bin/minimal.elf";
  };

  minimal = libs.mkRoot {
    name = "minimal";
    root = icecapSrcAbsSplit ./minimal;
    propagatedBuildInputs = with libs; [
      icecap-runtime-root
      icecap-utils
    ];
  };

})
